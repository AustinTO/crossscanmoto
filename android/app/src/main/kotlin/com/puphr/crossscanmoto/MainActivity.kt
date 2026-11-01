package com.puphr.crossscanmoto

import android.Manifest
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothDevice
import android.bluetooth.BluetoothSocket
import android.content.pm.PackageManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import java.io.IOException
import java.util.UUID
import java.util.concurrent.Executors
import java.util.ArrayDeque

class MainActivity : FlutterActivity() {
    private val methods = "crossscanmoto/bluetooth"
    private val events = "crossscanmoto/bluetooth/events"
    private val spp = UUID.fromString("00001101-0000-1000-8000-00805F9B34FB")
    private val io = Executors.newSingleThreadExecutor()
    private val main = Handler(Looper.getMainLooper())
    private var sink: EventChannel.EventSink? = null
    private val pendingEvents = ArrayDeque<ByteArray>()
    @Volatile private var socket: BluetoothSocket? = null
    @Volatile private var permissionResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, events).setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, eventSink: EventChannel.EventSink?) {
                    sink = eventSink
                    while (pendingEvents.isNotEmpty()) eventSink?.success(pendingEvents.removeFirst())
                }
                override fun onCancel(arguments: Any?) { sink = null }
            })
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, methods).setMethodCallHandler { call, result ->
            when (call.method) {
                "pairedDevices" -> withConnectPermission(result) {
                    val adapter = BluetoothAdapter.getDefaultAdapter()
                    if (adapter == null) result.error("UNAVAILABLE", "Bluetooth is not available", null)
                    else result.success(adapter.bondedDevices.map { mapOf("name" to (it.name ?: it.address), "address" to it.address) })
                }
                "connect" -> {
                    val address = call.argument<String>("address")
                    if (address.isNullOrBlank()) result.error("ARGUMENT", "A paired device address is required", null)
                    else withConnectPermission(result) { connect(address, result) }
                }
                "write" -> {
                    val bytes = call.argument<ByteArray>("bytes")
                    if (bytes == null) result.error("ARGUMENT", "Bytes are required", null)
                    else io.execute {
                        try {
                            val out = socket?.outputStream ?: throw IOException("Bluetooth is not connected")
                            out.write(bytes); out.flush()
                            main.post { result.success(null) }
                        } catch (e: Exception) { main.post { result.error("WRITE_FAILED", e.message, null) } }
                    }
                }
                "close" -> {
                    pendingEvents.clear()
                    closeSocket()
                    main.post { sink?.endOfStream(); result.success(null) }
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun withConnectPermission(result: MethodChannel.Result, action: () -> Unit) {
        if (Build.VERSION.SDK_INT < 31 || checkSelfPermission(Manifest.permission.BLUETOOTH_CONNECT) == PackageManager.PERMISSION_GRANTED) {
            action(); return
        }
        if (permissionResult != null) { result.error("PERMISSION_PENDING", "Bluetooth permission request is already pending", null); return }
        permissionResult = object : MethodChannel.Result {
            override fun success(value: Any?) { permissionResult = null; action() }
            override fun error(code: String, message: String?, details: Any?) { permissionResult = null; result.error(code, message, details) }
            override fun notImplemented() { permissionResult = null; result.notImplemented() }
        }
        requestPermissions(arrayOf(Manifest.permission.BLUETOOTH_CONNECT), 714)
        permissionResult?.let { pending -> permissionCallbacks[714] = pending }
    }

    private val permissionCallbacks = mutableMapOf<Int, MethodChannel.Result>()
    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        val callback = permissionCallbacks.remove(requestCode) ?: return
        if (grantResults.firstOrNull() == PackageManager.PERMISSION_GRANTED) callback.success(null)
        else callback.error("PERMISSION_DENIED", "Bluetooth connect permission was denied", null)
    }

    private fun connect(address: String, result: MethodChannel.Result) {
        pendingEvents.clear()
        io.execute {
            var candidate: BluetoothSocket? = null
            try {
                closeSocket()
                val adapter = BluetoothAdapter.getDefaultAdapter() ?: throw IOException("Bluetooth is not available")
                if (!adapter.isEnabled) throw IOException("Bluetooth is turned off")
                val device: BluetoothDevice = adapter.getRemoteDevice(address)
                val newSocket = device.createRfcommSocketToServiceRecord(spp)
                candidate = newSocket
                socket = newSocket
                newSocket.connect()
                main.post { result.success(mapOf("name" to (device.name ?: address), "address" to address)) }
                Thread({ readLoop(newSocket) }, "bluetooth-rfcomm-reader").apply { isDaemon = true; start() }
            } catch (e: Exception) {
                if (candidate != null && socket === candidate) socket = null
                try { candidate?.close() } catch (_: Exception) { }
                main.post { result.error("CONNECT_FAILED", e.message ?: "Bluetooth connection failed", null) }
            }
        }
    }

    private fun readLoop(candidate: BluetoothSocket) {
        try {
                val input = candidate.inputStream
                val buffer = ByteArray(4096)
                while (socket === candidate) {
                    val n = input.read(buffer)
                    if (n < 0) break
                    val chunk = buffer.copyOf(n)
                    main.post { if (socket === candidate) publish(chunk) }
                }
                if (socket === candidate) {
                    socket = null; candidate.close()
                    main.post { sink?.endOfStream() }
                }
            } catch (e: Exception) {
                if (socket === candidate) {
                    socket = null
                    try { candidate.close() } catch (_: Exception) { }
                    main.post { sink?.endOfStream() }
                }
        }
    }

    private fun publish(bytes: ByteArray) {
        val currentSink = sink
        if (currentSink != null) currentSink.success(bytes)
        else {
            if (pendingEvents.size >= 64) pendingEvents.removeFirst()
            pendingEvents.addLast(bytes)
        }
    }

    private fun closeSocket() {
        val old = socket
        socket = null
        try { old?.close() } catch (_: Exception) { }
    }

    override fun onDestroy() { closeSocket(); io.shutdownNow(); super.onDestroy() }
}
