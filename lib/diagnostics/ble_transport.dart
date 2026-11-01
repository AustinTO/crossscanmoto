import 'dart:async';

import 'package:flutter/services.dart';

import 'elm_session.dart';

class BleCharacteristicInfo {
  const BleCharacteristicInfo({required this.uuid, required this.properties});

  final String uuid;
  final Set<String> properties;

  bool get canWrite =>
      properties.contains('write') || properties.contains('writeWithoutResponse');
  bool get canNotify =>
      properties.contains('notify') || properties.contains('indicate');
}

class BleServiceInfo {
  const BleServiceInfo({required this.uuid, required this.characteristics});

  final String uuid;
  final List<BleCharacteristicInfo> characteristics;
}

class BlePeripheralInfo {
  const BlePeripheralInfo({required this.id, required this.name});

  final String id;
  final String name;
}

/// A user-selected, discovered GATT byte-stream profile.
class BleGattProfile {
  const BleGattProfile({
    required this.serviceUuid,
    required this.writeUuid,
    required this.notifyUuid,
  });

  final String serviceUuid;
  final String writeUuid;
  final String notifyUuid;
}

/// Generic iOS CoreBluetooth LE transport. It discovers real GATT attributes
/// and never assumes a device name or UUID profile.
class BleAdapterTransport implements AdapterTransport {
  BleAdapterTransport._(this.device, this.services) {
    _subscription = _events.receiveBroadcastStream().listen(
      (event) => _incoming.add((event as Uint8List).toList(growable: false)),
      onError: _incoming.addError,
      onDone: _incoming.close,
    );
  }

  static const MethodChannel _methods = MethodChannel('crossscanmoto/ble');
  static const EventChannel _events = EventChannel('crossscanmoto/ble/events');

  final BlePeripheralInfo device;
  final List<BleServiceInfo> services;
  final StreamController<List<int>> _incoming =
      StreamController<List<int>>.broadcast();
  late final StreamSubscription<Object?> _subscription;
  bool _configured = false;
  bool _closed = false;

  static Future<List<BlePeripheralInfo>> scan() async {
    final result = await _methods.invokeListMethod<Object?>('scan');
    return (result ?? const <Object?>[])
        .map((item) {
          final map = Map<Object?, Object?>.from(item! as Map);
          return BlePeripheralInfo(id: map['id']! as String, name: map['name']! as String);
        })
        .toList(growable: false);
  }

  static Future<BleAdapterTransport> connect(BlePeripheralInfo device) async {
    final result = await _methods.invokeMapMethod<Object?, Object?>('connect', {'id': device.id});
    if (result == null) throw StateError('Bluetooth service discovery returned no result');
    final rawServices = result['services'] as List<Object?>? ?? const [];
    final services = rawServices.map((rawService) {
      final service = Map<Object?, Object?>.from(rawService! as Map);
      final rawCharacteristics = service['characteristics'] as List<Object?>? ?? const [];
      final characteristics = rawCharacteristics.map((rawCharacteristic) {
        final characteristic = Map<Object?, Object?>.from(rawCharacteristic! as Map);
        return BleCharacteristicInfo(
          uuid: characteristic['uuid']! as String,
          properties: Set<String>.unmodifiable(
              (characteristic['properties'] as List<Object?>? ?? const []).cast<String>()),
        );
      }).toList(growable: false);
      return BleServiceInfo(
        uuid: service['uuid']! as String,
        characteristics: List.unmodifiable(characteristics),
      );
    }).toList(growable: false);
    return BleAdapterTransport._(device, List.unmodifiable(services));
  }

  Future<void> configure(BleGattProfile profile) async {
    if (_closed) throw StateError('Bluetooth transport is closed');
    final service = services.where((item) =>
        item.uuid.toLowerCase() == profile.serviceUuid.toLowerCase()).firstOrNull;
    final write = service?.characteristics.where((item) =>
        item.uuid.toLowerCase() == profile.writeUuid.toLowerCase()).firstOrNull;
    final notify = service?.characteristics.where((item) =>
        item.uuid.toLowerCase() == profile.notifyUuid.toLowerCase()).firstOrNull;
    if (write == null || !write.canWrite || notify == null || !notify.canNotify) {
      throw ArgumentError('Profile must select discovered write and notify characteristics');
    }
    await _methods.invokeMethod<void>('configure', {
      'serviceUuid': profile.serviceUuid,
      'writeUuid': profile.writeUuid,
      'notifyUuid': profile.notifyUuid,
    });
    _configured = true;
  }

  @override
  Stream<List<int>> get incoming => _incoming.stream;

  @override
  Future<void> write(List<int> bytes) async {
    if (_closed) throw StateError('Bluetooth transport is closed');
    if (!_configured) throw StateError('Select and configure a GATT profile first');
    await _methods.invokeMethod<void>('write', {'bytes': Uint8List.fromList(bytes)});
  }

  @override
  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    try {
      await _methods.invokeMethod<void>('close');
    } finally {
      await _subscription.cancel();
      await _incoming.close();
    }
  }
}
