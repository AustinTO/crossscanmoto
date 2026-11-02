import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:crossscanmoto/diagnostics/elm_session.dart';
import 'package:crossscanmoto/diagnostics/protocol_setup.dart';

class _ScriptedTransport implements AdapterTransport {
  final controller = StreamController<List<int>>();
  final writes = <String>[];
  final replies = <String>[];

  @override
  Stream<List<int>> get incoming => controller.stream;

  @override
  Future<void> write(List<int> bytes) async {
    writes.add(ascii.decode(bytes).replaceFirst('\r', ''));
    controller.add(ascii.encode('${replies.removeAt(0)}\r>'));
  }

  @override
  Future<void> close() => controller.close();
}

void main() {
  test('failed reconfiguration invalidates the previous ECU target', () async {
    final transport = _ScriptedTransport()
      ..replies.addAll(List.filled(11, 'OK'));
    final session = ElmSession(transport);
    final link = BmwBikeUdsLink(session);

    expect(await link.configure(id: 0x62), isTrue);
    expect(link.isConfigured, isTrue);
    transport.replies.add('ERROR');

    expect(await link.configure(id: 0x64), isFalse);
    expect(link.isConfigured, isFalse);
    await expectLater(link.request([0x22, 0xe1, 0x19]), throwsStateError);
    expect(transport.writes.last, 'ATSPB');
    await session.close();
  });

  group('BmwBikeUdsLink decodeSingleTokenResponse', () {
    test('decodes valid single token frame', () {
      final payload = BmwBikeUdsLink.decodeSingleTokenResponse(['412000362E119']);
      expect(payload, [0x62, 0xe1, 0x19]);
    });

    test('ignores ELM boilerplate lines and leading/trailing whitespace', () {
      final payload = BmwBikeUdsLink.decodeSingleTokenResponse([
        'SEARCHING...',
        '  412000362E119  ',
        '',
      ]);
      expect(payload, [0x62, 0xe1, 0x19]);
    });

    test('drains response-pending NRC 0x78 when followed by final response', () {
      final payload = BmwBikeUdsLink.decodeSingleTokenResponse([
        '41200037F2278',
        '412000362E119',
      ]);
      expect(payload, [0x62, 0xe1, 0x19]);
    });

    test('returns NRC 0x78 when only pending frame is returned', () {
      final payload = BmwBikeUdsLink.decodeSingleTokenResponse(['41200037F2278']);
      expect(payload, [0x7f, 0x22, 0x78]);
    });

    test('rejects multiple non-pending response tokens', () {
      expect(
        () => BmwBikeUdsLink.decodeSingleTokenResponse([
          '412000362E119',
          '412000362E12A',
        ]),
        throwsFormatException,
      );
    });

    test('rejects truncated header and payload', () {
      expect(
        () => BmwBikeUdsLink.decodeSingleTokenResponse(['412']),
        throwsFormatException,
      );
      expect(
        () => BmwBikeUdsLink.decodeSingleTokenResponse(['412000562E1']),
        throwsFormatException,
      );
    });
  });
}
