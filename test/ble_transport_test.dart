import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:crossscanmoto/diagnostics/ble_transport.dart';

const _methods = MethodChannel('crossscanmoto/ble');
const _events = EventChannel('crossscanmoto/ble/events');
const _deviceId = 'F1CE0000-0000-4000-8000-000000000001';
const _serviceId = 'F1CE0000-0000-4000-8000-000000000002';
const _writeId = 'F1CE0000-0000-4000-8000-000000000003';
const _notifyId = 'F1CE0000-0000-4000-8000-000000000004';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  tearDown(() {
    messenger.setMockMethodCallHandler(_methods, null);
    messenger.setMockStreamHandler(_events, null);
  });

  test('scan maps discovered peripheral identifiers and names', () async {
    messenger.setMockMethodCallHandler(_methods, (call) async {
      expect(call.method, 'scan');
      return [
        {'id': _deviceId, 'name': 'Diagnostic adapter'},
      ];
    });

    final devices = await BleAdapterTransport.scan();

    expect(devices, hasLength(1));
    expect(devices.single.id, _deviceId);
    expect(devices.single.name, 'Diagnostic adapter');
  });

  test('connect discovers profile and configure validates selected pair',
      () async {
    final calls = <MethodCall>[];
    messenger.setMockMethodCallHandler(_methods, (call) async {
      calls.add(call);
      if (call.method == 'connect') {
        expect(call.arguments, {'id': _deviceId});
        return {
          'id': _deviceId,
          'services': [
            {
              'uuid': _serviceId,
              'characteristics': [
                {
                  'uuid': _writeId,
                  'properties': ['writeWithoutResponse']
                },
                {
                  'uuid': _notifyId,
                  'properties': ['notify']
                },
                {
                  'uuid': 'F1CE0000-0000-4000-8000-000000000005',
                  'properties': ['read']
                },
              ],
            },
          ],
        };
      }
      return null;
    });

    final transport = await BleAdapterTransport.connect(
      const BlePeripheralInfo(id: _deviceId, name: 'Diagnostic adapter'),
    );
    expect(transport.services.single.uuid, _serviceId);
    expect(transport.services.single.characteristics, hasLength(3));

    await expectLater(
      transport.configure(const BleGattProfile(
        serviceUuid: _serviceId,
        writeUuid: _notifyId,
        notifyUuid: _writeId,
      )),
      throwsArgumentError,
    );
    expect(calls.map((call) => call.method), ['connect']);

    await transport.configure(const BleGattProfile(
      serviceUuid: _serviceId,
      writeUuid: _writeId,
      notifyUuid: _notifyId,
    ));
    expect(calls.map((call) => call.method), ['connect', 'configure']);
    await transport.close();
    expect(calls.last.method, 'close');
  });

  test('write requires a configured profile and forwards byte payload',
      () async {
    messenger.setMockMethodCallHandler(_methods, (call) async {
      if (call.method == 'connect') {
        return {
          'id': _deviceId,
          'services': [
            {
              'uuid': _serviceId,
              'characteristics': [
                {
                  'uuid': _writeId,
                  'properties': ['write']
                },
                {
                  'uuid': _notifyId,
                  'properties': ['indicate']
                },
              ],
            },
          ],
        };
      }
      return null;
    });
    final transport = await BleAdapterTransport.connect(
      const BlePeripheralInfo(id: _deviceId, name: 'Adapter'),
    );
    await expectLater(transport.write([1]), throwsStateError);
    await transport.configure(const BleGattProfile(
      serviceUuid: _serviceId,
      writeUuid: _writeId,
      notifyUuid: _notifyId,
    ));

    final data = [0x01, 0x7e, 0xff];
    messenger.setMockMethodCallHandler(_methods, (call) async {
      if (call.method == 'write') {
        expect(call.arguments, {'bytes': Uint8List.fromList(data)});
      }
      return null;
    });
    await transport.write(data);
    await transport.close();
    await expectLater(transport.write(data), throwsStateError);
  });

  test('notification bytes and stream errors reach transport consumers',
      () async {
    messenger.setMockMethodCallHandler(_methods, (call) async {
      if (call.method == 'connect') {
        return {
          'id': _deviceId,
          'services': <Object?>[],
        };
      }
      return null;
    });
    MockStreamHandlerEventSink? sink;
    messenger.setMockStreamHandler(
      _events,
      MockStreamHandler.inline(onListen: (_, events) => sink = events),
    );
    final transport = await BleAdapterTransport.connect(
      const BlePeripheralInfo(id: _deviceId, name: 'Adapter'),
    );
    final received = <List<int>>[];
    final errors = <Object>[];
    final done = Completer<void>();
    final subscription = transport.incoming.listen(
      received.add,
      onError: (Object error) => errors.add(error),
      onDone: done.complete,
    );

    sink!.success(Uint8List.fromList([0x41, 0x54, 0x5a]));
    await Future<void>.delayed(Duration.zero);
    expect(received, [
      [0x41, 0x54, 0x5a]
    ]);

    sink!.error(code: 'READ_FAILED', message: 'notification read failed');
    await Future<void>.delayed(Duration.zero);
    expect(errors, hasLength(1));
    expect(errors.single, isA<PlatformException>());
    sink!.endOfStream();
    await done.future;
    await subscription.cancel();
    await transport.close();
  });

  test('platform scan failures are preserved as platform exceptions', () async {
    messenger.setMockMethodCallHandler(_methods, (_) async {
      throw PlatformException(
          code: 'BLE_UNAVAILABLE', message: 'Bluetooth off');
    });

    await expectLater(
      BleAdapterTransport.scan(),
      throwsA(isA<PlatformException>()
          .having((error) => error.code, 'code', 'BLE_UNAVAILABLE')),
    );
  });
}
