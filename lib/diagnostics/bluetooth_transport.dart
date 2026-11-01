import 'dart:async';

import 'package:flutter/services.dart';

import 'elm_session.dart';

/// A previously paired Bluetooth Classic device.
class PairedBluetoothDevice {
  const PairedBluetoothDevice({required this.name, required this.address});

  final String name;
  final String address;

  factory PairedBluetoothDevice.fromMap(Map<Object?, Object?> map) =>
      PairedBluetoothDevice(
        name: map['name']! as String,
        address: map['address']! as String,
      );
}

/// Android RFCOMM Serial Port Profile transport for ELM327 adapters.
class BluetoothAdapterTransport implements AdapterTransport {
  BluetoothAdapterTransport._(this.device) {
    _subscription = _events.receiveBroadcastStream().listen(
      (event) => _incoming.add((event as Uint8List).toList(growable: false)),
      onError: _incoming.addError,
      onDone: _incoming.close,
    );
  }

  static const MethodChannel _methods = MethodChannel('crossscanmoto/bluetooth');
  static const EventChannel _events =
      EventChannel('crossscanmoto/bluetooth/events');

  final PairedBluetoothDevice device;
  final StreamController<List<int>> _incoming =
      StreamController<List<int>>.broadcast();
  late final StreamSubscription<Object?> _subscription;
  bool _closed = false;

  static Future<List<PairedBluetoothDevice>> pairedDevices() async {
    final result = await _methods.invokeListMethod<Object?>('pairedDevices');
    return (result ?? const <Object?>[])
        .map((item) => PairedBluetoothDevice.fromMap(
            Map<Object?, Object?>.from(item! as Map)))
        .toList(growable: false);
  }

  static Future<BluetoothAdapterTransport> connect(
      PairedBluetoothDevice device) async {
    final transport = BluetoothAdapterTransport._(device);
    try {
      await _methods.invokeMethod<void>('connect', {'address': device.address});
      return transport;
    } catch (_) {
      await transport._subscription.cancel();
      await transport._incoming.close();
      rethrow;
    }
  }

  @override
  Stream<List<int>> get incoming => _incoming.stream;

  @override
  Future<void> write(List<int> bytes) async {
    if (_closed) throw StateError('Bluetooth transport is closed');
    await _methods.invokeMethod<void>(
        'write', {'bytes': Uint8List.fromList(bytes)});
  }

  @override
  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    await _methods.invokeMethod<void>('close');
    await _subscription.cancel();
    await _incoming.close();
  }
}
