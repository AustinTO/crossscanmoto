import 'package:flutter_test/flutter_test.dart';
import 'package:crossscanmoto/diagnostics/uds_client.dart';

class FakeUdsLink implements UdsRequestLink {
  FakeUdsLink(this.reply);
  final List<int> Function(List<int> request) reply;
  List<int>? requestBytes;
  Duration? requestTimeout;

  @override
  Future<List<int>> request(List<int> payload, {Duration? timeout}) async {
    requestBytes = List.of(payload);
    requestTimeout = timeout;
    return reply(payload);
  }
}

void main() {
  group('ReadDataByIdentifier', () {
    test('sends DID and returns only the echoed DID data', () async {
      final link = FakeUdsLink((_) => [0x62, 0xf1, 0x90, 0x12, 0x34]);
      final client = UdsClient(link, timeout: const Duration(seconds: 2));

      expect(await client.readDataByIdentifier(0xf190), [0x12, 0x34]);
      expect(link.requestBytes, [0x22, 0xf1, 0x90]);
      expect(link.requestTimeout, const Duration(seconds: 2));
    });

    test('rejects missing and mismatched echoed DIDs', () async {
      final short = UdsClient(FakeUdsLink((_) => [0x62, 0xf1]));
      await expectLater(short.readDataByIdentifier(0xf190), throwsFormatException);

      final wrong = UdsClient(FakeUdsLink((_) => [0x62, 0xf1, 0x91, 0]));
      await expectLater(wrong.readDataByIdentifier(0xf190), throwsFormatException);
    });

    test('rejects out of range DID before sending', () async {
      final link = FakeUdsLink((_) => [0x62]);
      await expectLater(UdsClient(link).readDataByIdentifier(0x10000),
          throwsRangeError);
      expect(link.requestBytes, isNull);
    });
  });

  group('ReadDTCInformation', () {
    test('parses status availability and four byte DTC records', () async {
      final link = FakeUdsLink((_) => [
            0x59, 0x02, 0x2f,
            0x01, 0x23, 0x45, 0x08,
            0xab, 0xcd, 0xef, 0x2f,
          ]);
      final report = await UdsClient(link).readDtcByStatusMask(0x08);

      expect(link.requestBytes, [0x19, 0x02, 0x08]);
      expect(report.statusAvailabilityMask, 0x2f);
      expect(report.dtcs.map((dtc) => [dtc.code, dtc.status]), [
        [0x012345, 0x08],
        [0xabcdef, 0x2f],
      ]);
    });

    test('rejects truncated, misaligned, and wrong-subfunction responses', () async {
      for (final payload in [
        [0x59, 0x02],
        [0x59, 0x02, 0xff, 0x12],
        [0x59, 0x03, 0xff],
      ]) {
        await expectLater(
          UdsClient(FakeUdsLink((_) => payload)).readDtcByStatusMask(0xff),
          throwsFormatException,
        );
      }
    });
  });

  test('clear DTC validates three byte group and accepts positive confirmation',
      () async {
    final link = FakeUdsLink((_) => [0x54]);
    await UdsClient(link).clearDtc(group: 0x123456);
    expect(link.requestBytes, [0x14, 0x12, 0x34, 0x56]);

    final invalid = FakeUdsLink((_) => [0x54]);
    await expectLater(UdsClient(invalid).clearDtc(group: 0x1000000),
        throwsRangeError);
    expect(invalid.requestBytes, isNull);
  });

  test('session control validates and returns session timing bytes', () async {
    final link = FakeUdsLink((_) => [0x50, 0x03, 0x00, 0x32, 0x01, 0xf4]);
    expect(await UdsClient(link).diagnosticSessionControl(0x03),
        [0x00, 0x32, 0x01, 0xf4]);
    expect(link.requestBytes, [0x10, 0x03]);

    await expectLater(
      UdsClient(FakeUdsLink((_) => [0x50, 0x03]))
          .diagnosticSessionControl(0x83),
      throwsArgumentError,
    );
    await expectLater(
      UdsClient(FakeUdsLink((_) => [0x50, 0x02]))
          .diagnosticSessionControl(0x03),
      throwsFormatException,
    );
  });

  test('negative responses expose service and NRC as a typed error', () async {
    final client = UdsClient(FakeUdsLink((_) => [0x7f, 0x22, 0x31]));
    await expectLater(
      client.readDataByIdentifier(0xf190),
      throwsA(isA<UdsNegativeResponseException>()
          .having((error) => error.service, 'service', 0x22)
          .having((error) => error.code, 'NRC', 0x31)
          .having((error) => error.description, 'description', 'Request out of range')),
    );
  });

  test('pending response handling is delegated to the request link', () async {
    var calls = 0;
    final link = FakeUdsLink((_) {
      calls++;
      // The link models waiting through an initial NRC 0x78 and returning the
      // final positive payload to the client.
      return [0x62, 0xf1, 0x90, 0x42];
    });
    expect(await UdsClient(link).readDataByIdentifier(0xf190), [0x42]);
    expect(calls, 1);
  });
}
