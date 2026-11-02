import 'package:flutter_test/flutter_test.dart';
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

void main() {
  final dateTime = DateTime(2026, 11, 1, 12, 0);
  final serviceDate = DateTime(2027, 6, 15);

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
}
