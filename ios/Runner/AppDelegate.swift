import Flutter
import UIKit
import CoreBluetooth

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private var bleBridge: CrossScanMotoBleBridge?
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "CrossScanMotoBleBridge") {
      bleBridge = CrossScanMotoBleBridge(messenger: registrar.messenger())
    }
  }
}

/// Generic CoreBluetooth GATT transport. It deliberately does not assume
/// adapter names or service/characteristic UUIDs.
private final class CrossScanMotoBleBridge: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate, FlutterStreamHandler {
  private let methods = "crossscanmoto/ble"
  private let events = "crossscanmoto/ble/events"
  private let central: CBCentralManager
  private var eventSink: FlutterEventSink?
  private var devices: [UUID: CBPeripheral] = [:]
  private var scanResult: FlutterResult?
  private var scanTimeout: DispatchWorkItem?
  private var connectResult: FlutterResult?
  private var pendingConnectPeripheral: UUID?
  private var connectTimeout: DispatchWorkItem?
  private var pendingServiceCount = 0
  private var serviceDiscoveryError: Error?
  private var configuredRx: CBCharacteristic?
  private var configuredTx: CBCharacteristic?
  private var configureResult: FlutterResult?
  private var configureTimeout: DispatchWorkItem?
  private var pendingConfigurationID: UUID?
  private var writeQueue: [(Data, FlutterResult)] = []
  private var activeWrite: (Data, FlutterResult, Int)?

  init(messenger: FlutterBinaryMessenger) {
    central = CBCentralManager(delegate: nil, queue: .main)
    super.init()
    central.delegate = self
    FlutterMethodChannel(name: methods, binaryMessenger: messenger).setMethodCallHandler { [weak self] call, result in
      self?.handle(call, result: result)
    }
    FlutterEventChannel(name: events, binaryMessenger: messenger).setStreamHandler(self)
  }

  func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    eventSink = events
    return nil
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    eventSink = nil
    return nil
  }

  private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "scan":
      guard central.state == .poweredOn else { result(FlutterError(code: "BLE_UNAVAILABLE", message: "Bluetooth is not powered on", details: nil)); return }
      if scanResult != nil { result(FlutterError(code: "SCAN_ACTIVE", message: "A Bluetooth scan is already active", details: nil)); return }
      devices.removeAll()
      scanResult = result
      central.scanForPeripherals(withServices: nil)
      let timeout = DispatchWorkItem { [weak self] in self?.finishScan() }
      scanTimeout = timeout
      DispatchQueue.main.asyncAfter(deadline: .now() + 6, execute: timeout)
    case "connect":
      guard let args = call.arguments as? [String: Any], let identifier = args["id"] as? String,
            let uuid = UUID(uuidString: identifier), let peripheral = devices[uuid] else {
        result(FlutterError(code: "DEVICE_NOT_FOUND", message: "Scan and select a discovered Bluetooth LE device first", details: nil)); return
      }
      guard central.state == .poweredOn else { result(FlutterError(code: "BLE_UNAVAILABLE", message: "Bluetooth is not powered on", details: nil)); return }
      if connectResult != nil { result(FlutterError(code: "CONNECT_ACTIVE", message: "A Bluetooth connection is already pending", details: nil)); return }
      connectResult = result
      pendingConnectPeripheral = peripheral.identifier
      serviceDiscoveryError = nil
      peripheral.delegate = self
      central.connect(peripheral)
      let timeout = DispatchWorkItem { [weak self, weak peripheral] in
        guard let self, self.connectResult != nil,
              self.pendingConnectPeripheral == peripheral?.identifier else { return }
        if let peripheral { self.central.cancelPeripheralConnection(peripheral) }
        self.connectResult?(FlutterError(code: "CONNECT_TIMEOUT", message: "Bluetooth connection timed out", details: nil))
        self.connectResult = nil
        self.pendingConnectPeripheral = nil
        self.configuredRx = nil; self.configuredTx = nil
      }
      connectTimeout = timeout
      DispatchQueue.main.asyncAfter(deadline: .now() + 15, execute: timeout)
    case "configure":
      if configureResult != nil {
        result(FlutterError(code: "CONFIGURE_ACTIVE", message: "A GATT configuration is already pending", details: nil)); return
      }
      guard let args = call.arguments as? [String: Any],
            let serviceId = args["serviceUuid"] as? String,
            let txId = args["writeUuid"] as? String,
            let rxId = args["notifyUuid"] as? String,
            let peripheral = connectedPeripheral,
            let service = peripheral.services?.first(where: { $0.uuid.uuidString.caseInsensitiveCompare(serviceId) == .orderedSame }),
            let tx = service.characteristics?.first(where: { $0.uuid.uuidString.caseInsensitiveCompare(txId) == .orderedSame }),
            let rx = service.characteristics?.first(where: { $0.uuid.uuidString.caseInsensitiveCompare(rxId) == .orderedSame }) else {
        result(FlutterError(code: "GATT_PROFILE_INVALID", message: "Select discovered service, write, and notify characteristics", details: nil)); return
      }
      let writable = tx.properties.contains(.write) || tx.properties.contains(.writeWithoutResponse)
      let notifiable = rx.properties.contains(.notify) || rx.properties.contains(.indicate)
      guard writable && notifiable else { result(FlutterError(code: "GATT_PROFILE_INVALID", message: "Selected characteristics do not support writing and notifications", details: nil)); return }
      configuredTx = tx
      configuredRx = rx
      configureResult = result
      let configurationID = UUID()
      pendingConfigurationID = configurationID
      let timeout = DispatchWorkItem { [weak self, weak peripheral] in
        guard let self, self.pendingConfigurationID == configurationID,
              self.configureResult != nil else { return }
        self.configureResult?(FlutterError(code: "CONFIGURE_TIMEOUT", message: "Enabling GATT notifications timed out", details: nil))
        self.configureResult = nil
        self.pendingConfigurationID = nil
        self.configuredRx = nil; self.configuredTx = nil
        if let peripheral { peripheral.setNotifyValue(false, for: rx) }
      }
      configureTimeout?.cancel()
      configureTimeout = timeout
      DispatchQueue.main.asyncAfter(deadline: .now() + 10, execute: timeout)
      peripheral.setNotifyValue(true, for: rx)
    case "write":
      guard let args = call.arguments as? [String: Any], let data = args["bytes"] as? FlutterStandardTypedData else {
        result(FlutterError(code: "ARGUMENT", message: "Bytes are required", details: nil)); return
      }
      guard configuredTx != nil, let peripheral = connectedPeripheral else {
        result(FlutterError(code: "NOT_CONFIGURED", message: "Connect and configure a GATT profile before writing", details: nil)); return
      }
      writeQueue.append((data.data, result))
      startNextWrite(on: peripheral)
    case "close":
      let peripheral = connectedPeripheral ?? pendingConnectPeripheral.flatMap { devices[$0] }
      connectTimeout?.cancel(); connectTimeout = nil
      configureTimeout?.cancel(); configureTimeout = nil
      configuredRx = nil; configuredTx = nil
      if let peripheral { central.cancelPeripheralConnection(peripheral) }
      if let pending = connectResult {
        pending(FlutterError(code: "CLOSED", message: "Bluetooth connection was closed", details: nil))
        connectResult = nil; pendingConnectPeripheral = nil
      }
      configureResult?(FlutterError(code: "CLOSED", message: "Bluetooth connection was closed", details: nil))
      configureResult = nil; pendingConfigurationID = nil
      failWrites(code: "CLOSED", message: "Bluetooth connection was closed")
      eventSink?(FlutterEndOfEventStream)
      result(nil)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private var connectedPeripheral: CBPeripheral? {
    devices.values.first(where: { $0.state == .connected })
  }

  private func finishScan() {
    guard let result = scanResult else { return }
    scanResult = nil
    scanTimeout?.cancel(); scanTimeout = nil
    central.stopScan()
    result(devices.values.map { peripheral in
      ["id": peripheral.identifier.uuidString, "name": peripheral.name ?? peripheral.identifier.uuidString]
    })
  }

  func centralManagerDidUpdateState(_ central: CBCentralManager) {
    if central.state != .poweredOn {
      scanTimeout?.cancel(); scanTimeout = nil
      central.stopScan()
      scanResult?(FlutterError(code: "BLE_UNAVAILABLE", message: "Bluetooth is not powered on", details: nil)); scanResult = nil
      connectTimeout?.cancel(); connectTimeout = nil
      let unavailable = FlutterError(code: "BLE_UNAVAILABLE", message: "Bluetooth is not powered on", details: nil)
      connectResult?(unavailable); connectResult = nil
      connectedPeripheral.map { central.cancelPeripheralConnection($0) }
      pendingConnectPeripheral.flatMap { devices[$0] }.map { central.cancelPeripheralConnection($0) }
      pendingConnectPeripheral = nil
      configureTimeout?.cancel(); configureTimeout = nil
      configureResult?(unavailable); configureResult = nil; pendingConfigurationID = nil
      configuredRx = nil; configuredTx = nil
      failWrites(code: "BLE_UNAVAILABLE", message: "Bluetooth is not powered on")
      eventSink?(unavailable)
      eventSink?(FlutterEndOfEventStream)
      eventSink = nil
    }
  }

  func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber) {
    devices[peripheral.identifier] = peripheral
  }

  func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
    peripheral.delegate = self
    peripheral.discoverServices(nil)
  }

  func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
    connectTimeout?.cancel(); connectTimeout = nil
    connectResult?(FlutterError(code: "CONNECT_FAILED", message: error?.localizedDescription ?? "Bluetooth connection failed", details: nil))
    connectResult = nil
    pendingConnectPeripheral = nil
  }

  func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
    if pendingConnectPeripheral == peripheral.identifier {
      connectTimeout?.cancel(); connectTimeout = nil
      connectResult?(FlutterError(code: "DISCONNECTED", message: error?.localizedDescription ?? "Bluetooth disconnected before discovery completed", details: nil))
      connectResult = nil; pendingConnectPeripheral = nil
    }
    configureTimeout?.cancel(); configureTimeout = nil
    configuredRx = nil; configuredTx = nil
    configureResult?(FlutterError(code: "DISCONNECTED", message: error?.localizedDescription ?? "Bluetooth device disconnected", details: nil)); configureResult = nil; pendingConfigurationID = nil
    failWrites(code: "DISCONNECTED", message: error?.localizedDescription ?? "Bluetooth device disconnected")
    eventSink?(FlutterEndOfEventStream)
  }

  func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
    if let error { serviceDiscoveryError = error }
    let services = peripheral.services ?? []
    pendingServiceCount = services.count
    if services.isEmpty { finishServiceDiscovery(peripheral) }
    else { services.forEach { peripheral.discoverCharacteristics(nil, for: $0) } }
  }

  func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
    if let error { serviceDiscoveryError = error }
    pendingServiceCount -= 1
    if pendingServiceCount <= 0 { finishServiceDiscovery(peripheral) }
  }

  private func finishServiceDiscovery(_ peripheral: CBPeripheral) {
    guard let result = connectResult else { return }
    connectTimeout?.cancel(); connectTimeout = nil
    connectResult = nil
    pendingConnectPeripheral = nil
    if let error = serviceDiscoveryError {
      result(FlutterError(code: "GATT_DISCOVERY_FAILED", message: error.localizedDescription, details: nil)); return
    }
    let profile = (peripheral.services ?? []).map { service in
      ["uuid": service.uuid.uuidString, "characteristics": (service.characteristics ?? []).map { characteristic in
        ["uuid": characteristic.uuid.uuidString, "properties": propertyNames(characteristic.properties)] as [String: Any]
      }] as [String: Any]
    }
    result(["id": peripheral.identifier.uuidString, "services": profile])
  }

  private func propertyNames(_ properties: CBCharacteristicProperties) -> [String] {
    var names: [String] = []
    if properties.contains(.read) { names.append("read") }
    if properties.contains(.write) { names.append("write") }
    if properties.contains(.writeWithoutResponse) { names.append("writeWithoutResponse") }
    if properties.contains(.notify) { names.append("notify") }
    if properties.contains(.indicate) { names.append("indicate") }
    return names
  }

  func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
    guard characteristic == configuredRx, let result = configureResult else { return }
    configureTimeout?.cancel(); configureTimeout = nil
    configureResult = nil
    pendingConfigurationID = nil
    if let error { configuredRx = nil; result(FlutterError(code: "NOTIFY_FAILED", message: error.localizedDescription, details: nil)) }
    else if characteristic.isNotifying { result(nil) }
    else { configuredRx = nil; result(FlutterError(code: "NOTIFY_FAILED", message: "Peripheral did not enable notifications", details: nil)) }
  }

  func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
    guard characteristic == configuredRx else { return }
    if let error { eventSink?(FlutterError(code: "READ_FAILED", message: error.localizedDescription, details: nil)); return }
    if let value = characteristic.value { eventSink?(FlutterStandardTypedData(bytes: value)) }
  }

  private func startNextWrite(on peripheral: CBPeripheral) {
    guard activeWrite == nil, !writeQueue.isEmpty, let tx = configuredTx else { return }
    let (data, result) = writeQueue.removeFirst()
    activeWrite = (data, result, 0)
    sendNextWriteChunk(on: peripheral)
  }

  private func failWrites(code: String, message: String) {
    let error = FlutterError(code: code, message: message, details: nil)
    for (_, result) in writeQueue { result(error) }
    writeQueue.removeAll()
    activeWrite?.1(error)
    activeWrite = nil
  }

  func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
    guard characteristic == configuredTx, let activeWrite else { return }
    if let error {
      self.activeWrite = nil
      activeWrite.1(FlutterError(code: "WRITE_FAILED", message: error.localizedDescription, details: nil))
      startNextWrite(on: peripheral)
    } else { sendNextWriteChunk(on: peripheral) }
  }

  func peripheralIsReady(toSendWriteWithoutResponse peripheral: CBPeripheral) {
    sendNextWriteChunk(on: peripheral)
  }

  private func sendNextWriteChunk(on peripheral: CBPeripheral) {
    guard let (data, result, offset) = activeWrite, let tx = configuredTx else { return }
    if offset >= data.count {
      activeWrite = nil
      result(nil)
      startNextWrite(on: peripheral)
      return
    }
    let withResponse = tx.properties.contains(.write)
    if !withResponse && !peripheral.canSendWriteWithoutResponse { return }
    let type: CBCharacteristicWriteType = withResponse ? .withResponse : .withoutResponse
    let mtu = max(1, peripheral.maximumWriteValueLength(for: type))
    let nextOffset = min(data.count, offset + mtu)
    let chunk = data.subdata(in: offset..<nextOffset)
    activeWrite = (data, result, nextOffset)
    peripheral.writeValue(chunk, for: tx, type: type)
    if !withResponse { sendNextWriteChunk(on: peripheral) }
  }
}
