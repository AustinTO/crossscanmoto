import 'package:flutter_test/flutter_test.dart';
import 'package:crossscanmoto/diagnostics/kwp_client.dart';
import 'package:crossscanmoto/diagnostics/service_manager.dart';
import 'package:crossscanmoto/diagnostics/service_reset_protocol.dart';
import 'package:crossscanmoto/diagnostics/uds_client.dart';

class _RecordingLink implements UdsRequestLink {
  final requests = <List<int>>[];

  @override
  Future<List<int>> request(List<int> payload, {Duration? timeout}) async {
    requests.add(List.unmodifiable(payload));
    return const [0x6e, 0xe1, 0x2d];
  }
}

class _RecordingKwpLink implements KwpRequestLink {
  final requests = <List<int>>[];

  @override
  Future<List<int>> request(List<int> payload, {Duration? timeout}) async {
    requests.add(List.unmodifiable(payload));
    if (payload.first == 0x81) return [0xc1];
    if (payload.first == 0x3b) return [0x7b, payload[1]];
    return [0x7b];
  }

  @override
  Future<bool> startCommunication() async => true;
}

void main() {
  final dateTime = DateTime(2026, 11, 1, 12, 0);
  final serviceDate = DateTime(2027, 6, 15);

  group('UDS Service Reset Protocol', () {
    for (final action in BmwServiceResetAction.values) {
      test('rejects out-of-range mileage before encoding $action', () {
        for (final mileage in [-1, 0x10000]) {
          expect(
            () => BmwServiceResetProtocol.encodeWrites(
              action: action,
              vehicleDateTime: dateTime,
              nextServiceDate: serviceDate,
              nextServiceMileage: mileage,
            ),
            throwsRangeError,
          );
        }
      });
    }

    test('execute rejects invalid mileage before any ECU request', () async {
      final link = _RecordingLink();
      final protocol = BmwServiceResetProtocol(
        link: link,
        profile: BmwServiceResetProfile.udsServiceData,
        ecuKey: 'cuX_KOMB18',
        delay: (_) async {},
      );

      await expectLater(
        protocol.execute(
          action: BmwServiceResetAction.nextServiceDate,
          vehicleDateTime: dateTime,
          nextServiceDate: serviceDate,
          nextServiceMileage: 0x10000,
        ),
        throwsRangeError,
      );
      expect(link.requests, isEmpty);
    });

    test('accepts both 16-bit mileage boundaries without truncation', () {
      for (final mileage in [0, 0xffff]) {
        final write = BmwServiceResetProtocol.encodeWrites(
          action: BmwServiceResetAction.nextServiceMileage,
          vehicleDateTime: dateTime,
          nextServiceDate: serviceDate,
          nextServiceMileage: mileage,
        ).single;
        expect(write.data, [(mileage >> 8) & 0xff, mileage & 0xff]);
      }
    });
  });

  group('Legacy KWP Service Reset (qr.C / rr.C Parity)', () {
    test('executeKwp rejects invalid mileage before sending writes', () async {
      final kwpLink = _RecordingKwpLink();
      final result = await BmwServiceManager.executeKwp(
        item: const ServiceFunctionItem(
          type: ServiceFunctionType.setNextServiceMileage,
          title: 'Mileage',
          description: '',
          preconditions: '',
        ),
        link: kwpLink,
        ecuKey: 'cuMRKOMB18',
        nextServiceMileage: 70000,
      );

      expect(result.success, isFalse);
      expect(result.message, contains('0..65535'));
      expect(kwpLink.requests, isEmpty);
    });

    test('executeKwp sends Record P, Q, and R in exact order for setAllServiceData', () async {
      final kwpLink = _RecordingKwpLink();
      final testCarDate = DateTime(2026, 11, 2, 16, 45, 30);
      final testServiceDate = DateTime(2027, 11, 15);

      final result = await BmwServiceManager.executeKwp(
        item: const ServiceFunctionItem(
          type: ServiceFunctionType.setAllServiceData,
          title: 'All',
          description: '',
          preconditions: '',
        ),
        link: kwpLink,
        ecuKey: 'cuMRKOMB46',
        vehicleDateTime: testCarDate,
        nextServiceDate: testServiceDate,
        nextServiceMileage: 10000,
      );

      expect(result.success, isTrue);
      expect(result.message, contains('Legacy KWP service reset completed on cuMRKOMB46'));
      expect(result.newServiceDate, testServiceDate);
      expect(result.newServiceMileageKm, 10000);

      // Verify requests sent:
      // Filter out StartCommunication (81) to inspect Service 0x3B payloads
      final writes3b = kwpLink.requests.where((r) => r.first == 0x3b).toList();
      expect(writes3b.length, 3);

      // 1. Record P: 3B 10 hh mm ss dd MM yr_hi yr_lo
      // 16=0x10, 45=0x2D, 30=0x1E, 2=0x02, 11=0x0B, 2026=0x07EA
      expect(writes3b[0], [0x3b, 0x10, 0x10, 0x2d, 0x1e, 0x02, 0x0b, 0x07, 0xea]);

      // 2. Record Q: 3B 11 dd MM yr_hi yr_lo
      // 15=0x0F, 11=0x0B, 2027=0x07EB
      expect(writes3b[1], [0x3b, 0x11, 0x0f, 0x0b, 0x07, 0xeb]);

      // 3. Record R: 3B 12 mileage_hi mileage_lo
      // 10000=0x2710
      expect(writes3b[2], [0x3b, 0x12, 0x27, 0x10]);
    });

    test('executeKwp handles cancellation mid-sequence fail-safe', () async {
      final kwpLink = _RecordingKwpLink();
      var abort = false;

      final result = await BmwServiceManager.executeKwp(
        item: const ServiceFunctionItem(
          type: ServiceFunctionType.setAllServiceData,
          title: 'All',
          description: '',
          preconditions: '',
        ),
        link: kwpLink,
        ecuKey: 'cuMRKOMB',
        vehicleDateTime: DateTime(2026, 1, 1),
        nextServiceDate: DateTime(2027, 1, 1),
        nextServiceMileage: 5000,
        shouldAbort: () {
          // Abort after first request is sent
          if (kwpLink.requests.any((r) => r.first == 0x3b)) {
            abort = true;
          }
          return abort;
        },
      );

      expect(result.success, isFalse);
      expect(result.cancelled, isTrue);
      // Stopped after Record P; Record Q and R were not sent
      final writes3b = kwpLink.requests.where((r) => r.first == 0x3b).toList();
      expect(writes3b.length, 1);
    });
  });
}
