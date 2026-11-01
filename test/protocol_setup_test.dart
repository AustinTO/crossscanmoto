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
}
