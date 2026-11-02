import 'dart:async';
import 'dart:collection';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:crossscanmoto/diagnostics/elm_session.dart';
import 'package:crossscanmoto/diagnostics/kwp_client.dart';
import 'package:crossscanmoto/diagnostics/kwp_response.dart';

class _ScriptedTransport implements AdapterTransport {
  final controller = StreamController<List<int>>();
  final writes = <String>[];
  final replies = Queue<String>();

  @override
  Stream<List<int>> get incoming => controller.stream;

  @override
  Future<void> write(List<int> bytes) async {
    writes.add(ascii.decode(bytes).replaceFirst('\r', ''));
    final reply = replies.removeFirst();
    controller.add(ascii.encode('$reply\r>'));
  }

  @override
  Future<void> close() => controller.close();
}

String _elmFrame(List<int> payload) {
  final bytes = [payload.length, ...payload, 0];
  return bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();
}

void _configure(_ScriptedTransport transport) {
  transport.replies.addAll(List.filled(6, 'OK'));
}

Future<(ElmSession, _ScriptedTransport, BmwBikeKwpLink)> _newConfiguredLink({
  int address = 0x12,
  int maxBusyRetries = 2,
}) async {
  final transport = _ScriptedTransport();
  final session = ElmSession(transport);
  final link = BmwBikeKwpLink(session, maxBusyRetries: maxBusyRetries);
  _configure(transport);
  expect(await link.configure(ecuAddress: address), isTrue);
  return (session, transport, link);
}

void main() {
  group('BMW legacy KWP link', () {
    test(
      'configures the 1.83 KWP ELM profile and caches the ECU address',
      () async {
        final transport = _ScriptedTransport()
          ..replies.addAll(List.filled(6, 'OK'));
        final session = ElmSession(transport);
        final link = BmwBikeKwpLink(session);

        expect(await link.configure(ecuAddress: 0x12), isTrue);
        expect(transport.writes, [
          'ATPC',
          'ATAL',
          'ATSH8112F1',
          'ATWM8112F13E',
          'ATST50',
          'ATSP5',
        ]);
        expect(await link.configure(ecuAddress: 0x12), isTrue);
        expect(transport.writes, hasLength(6));
        await session.close();
      },
    );

    test('rejects an ECU address outside the one byte target range', () async {
      final transport = _ScriptedTransport();
      final session = ElmSession(transport);
      final link = BmwBikeKwpLink(session);

      await expectLater(link.configure(ecuAddress: 0x100), throwsRangeError);
      expect(transport.writes, isEmpty);
      await session.close();
    });

    test(
      'invalidates the prior ECU selection after failed reconfiguration',
      () async {
        final transport = _ScriptedTransport()
          ..replies.addAll(List.filled(6, 'OK'))
          ..replies.add('ERROR');
        final session = ElmSession(transport);
        final link = BmwBikeKwpLink(session);

        expect(await link.configure(ecuAddress: 0x12), isTrue);
        expect(await link.configure(ecuAddress: 0x13), isFalse);
        expect(link.isConfigured, isFalse);
        await expectLater(link.request([0x18]), throwsStateError);
        await session.close();
      },
    );

    test(
      'starts KWP communication and reads count-prefixed three-byte DTC rows',
      () async {
        final (session, transport, link) = await _newConfiguredLink();
        transport.replies
          ..add(_elmFrame([0xc1]))
          ..add(_elmFrame([0x58, 2, 0x01, 0x23, 0xaa, 0x04, 0x56, 0xbb]));

        final report = await KwpClient(link).readDtc();

        expect(report.dtcs.map((dtc) => [dtc.code, dtc.opaqueRecordByte]), [
          [0x0123, 0xaa],
          [0x0456, 0xbb],
        ]);
        expect(transport.writes.skip(6), ['81', '1802FFFF']);
        await session.close();
      },
    );

    test(
      'accepts the 1A80 probe when start communication is not supported',
      () async {
        final (session, transport, link) = await _newConfiguredLink();
        transport.replies
          ..add(_elmFrame([0x7f, 0x81, 0x11]))
          ..add(_elmFrame([0x5a, 0x80, 0x22]))
          ..add(_elmFrame([0x57, 0x10, 0x20]));

        expect(await KwpClient(link).readParameter(0x1234), [0x10, 0x20]);
        expect(transport.writes.skip(6), ['81', '1A80', '171234']);
        await session.close();
      },
    );

    test(
      'does not probe 1A80 for an NRC that echoes another service',
      () async {
        final (session, transport, link) = await _newConfiguredLink();
        transport.replies.add(_elmFrame([0x7f, 0x99, 0x11]));

        expect(await link.startCommunication(), isFalse);
        expect(transport.writes.skip(6), ['81']);
        await session.close();
      },
    );

    test(
      'probeAndIdentify rejects a mismatched StartCommunication NRC',
      () async {
        final (session, transport, link) = await _newConfiguredLink();
        transport.replies.add(_elmFrame([0x7f, 0x99, 0x12]));

        expect(await link.probeAndIdentify(), isNull);
        expect(transport.writes.skip(6), ['81']);
        await session.close();
      },
    );

    test('recognizes an ECU that already answers the 1A80 probe', () async {
      final (session, transport, link) = await _newConfiguredLink();
      transport.replies
        ..add(_elmFrame([0xc1]))
        ..add(_elmFrame([0x5a, 0x80, 0x00]));

      final identity = await link.probeAndIdentify();

      expect(identity, [0x5a, 0x80, 0x00]);
      expect(transport.writes.skip(6), ['81', '1A80']);
      await session.close();
    });

    test(
      'sends the recovered 14FFFF clear request and validates its positive SID',
      () async {
        final (session, transport, link) = await _newConfiguredLink();
        transport.replies
          ..add(_elmFrame([0xc1]))
          ..add(_elmFrame([0x54]));

        await KwpClient(link).clearDtc();
        expect(transport.writes.skip(6), ['81', '14FFFF']);
        await session.close();
      },
    );

    test('surfaces service-specific negative responses', () async {
      final (session, transport, link) = await _newConfiguredLink();
      transport.replies
        ..add(_elmFrame([0xc1]))
        ..add(_elmFrame([0x7f, 0x14, 0x31]));

      await expectLater(
        KwpClient(link).clearDtc(),
        throwsA(
          isA<KwpNegativeResponseException>()
              .having((error) => error.service, 'echoed service', 0x14)
              .having((error) => error.code, 'NRC', 0x31),
        ),
      );
      await session.close();
    });

    test(
      'rejects a negative response that echoes a different service',
      () async {
        final (session, transport, link) = await _newConfiguredLink();
        transport.replies
          ..add(_elmFrame([0xc1]))
          ..add(_elmFrame([0x7f, 0x17, 0x31]));

        await expectLater(KwpClient(link).clearDtc(), throwsFormatException);
        await session.close();
      },
    );

    test(
      'retries NRC 0x21 then drains pending replies before final payload',
      () async {
        final (session, transport, link) = await _newConfiguredLink();
        transport.replies
          ..add(_elmFrame([0x7f, 0x17, 0x21]))
          ..add('${_elmFrame([0x7f, 0x17, 0x78])}\r${_elmFrame([0x57, 0xaa])}');

        expect(await link.request([0x17]), [0x57, 0xaa]);
        expect(transport.writes.skip(6), ['17', '17']);
        await session.close();
      },
    );

    test(
      'reports pending when the ELM prompt arrives without a final frame',
      () async {
        final (session, transport, link) = await _newConfiguredLink();
        transport.replies.add(_elmFrame([0x7f, 0x17, 0x78]));

        await expectLater(
          link.request([0x17]),
          throwsA(isA<KwpResponsePendingException>()),
        );
        await session.close();
      },
    );

    test(
      'bounds repeated busy responses instead of recursing forever',
      () async {
        final (session, transport, link) = await _newConfiguredLink(
          maxBusyRetries: 1,
        );
        transport.replies
          ..add(_elmFrame([0x7f, 0x17, 0x21]))
          ..add(_elmFrame([0x7f, 0x17, 0x21]));

        await expectLater(
          link.request([0x17]),
          throwsA(
            isA<KwpBusyException>().having(
              (error) => error.retries,
              'retry count',
              1,
            ),
          ),
        );
        expect(transport.writes.skip(6), ['17', '17']);
        await session.close();
      },
    );

    test(
      'does not retry a busy negative response for another service',
      () async {
        final (session, transport, link) = await _newConfiguredLink();
        transport.replies
          ..add(_elmFrame([0xc1]))
          ..add(_elmFrame([0x7f, 0x99, 0x21]));

        await expectLater(KwpClient(link).clearDtc(), throwsFormatException);
        expect(transport.writes.skip(6), ['81', '14FFFF']);
        await session.close();
      },
    );

    test(
      'does not drain a response-pending frame for another service',
      () async {
        final (session, transport, link) = await _newConfiguredLink();
        transport.replies
          ..add(_elmFrame([0xc1]))
          ..add('${_elmFrame([0x7f, 0x99, 0x78])}\r${_elmFrame([0x54])}');

        await expectLater(KwpClient(link).clearDtc(), throwsFormatException);
        expect(transport.writes.skip(6), ['81', '14FFFF']);
        await session.close();
      },
    );

    test(
      'rejects truncated DTC rows and malformed ELM frame lengths',
      () async {
        final (session, transport, link) = await _newConfiguredLink();
        transport.replies
          ..add(_elmFrame([0xc1]))
          ..add(_elmFrame([0x58, 1, 0x12, 0x34]));

        await expectLater(KwpClient(link).readDtc(), throwsFormatException);
        expect(
          () => BmwBikeKwpLink.decodeElmResponseLines(['03 58 00 00']),
          throwsFormatException,
        );
        await session.close();
      },
    );

    test(
      'rejects a positive service response for a different request',
      () async {
        final (session, transport, link) = await _newConfiguredLink();
        transport.replies
          ..add(_elmFrame([0xc1]))
          ..add(_elmFrame([0x58, 0x00]));

        await expectLater(
          KwpClient(link).readParameter(0x1234),
          throwsFormatException,
        );
        await session.close();
      },
    );

    test('requires adapter configuration before sending KWP bytes', () async {
      final transport = _ScriptedTransport();
      final session = ElmSession(transport);
      final link = BmwBikeKwpLink(session);

      await expectLater(link.request([0x18]), throwsStateError);
      await expectLater(link.startCommunication(), throwsStateError);
      expect(transport.writes, isEmpty);
      await session.close();
    });

    test('decodes every KWP ELM frame and removes legacy status text', () {
      expect(
        BmwBikeKwpLink.decodeElmResponseLines([
          'SEARCHING...',
          'BUS INIT: OK',
          '03, 58, 01, 00, 00',
        ]),
        [
          [0x58, 0x01, 0x00],
        ],
      );
      expect(BmwBikeKwpLink.decodeElmResponseLines(['358010000']), [
        [0x58, 0x01, 0x00],
      ]);
    });
  });
}
