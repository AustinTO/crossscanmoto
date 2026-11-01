import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:crossscanmoto/diagnostic_session.dart';
import 'package:crossscanmoto/diagnostics/elm_session.dart';
import 'package:crossscanmoto/diagnostics/uds_client.dart';

void main() {
  final diagnosticSession = DiagnosticSession.instance;

  tearDown(() {
    diagnosticSession.detach();
  });

  test('new adapter and disconnect clear old protocol readiness', () async {
    final firstTransport = _FakeTransport();
    final firstElm = ElmSession(firstTransport);
    diagnosticSession.attach(firstElm, identity: 'first');
    diagnosticSession.attachUdsClient(UdsClient(_FakeUdsLink()));
    expect(diagnosticSession.protocolReady, isTrue);

    diagnosticSession.attach(ElmSession(_FakeTransport()), identity: 'second');
    expect(diagnosticSession.connected, isTrue);
    expect(diagnosticSession.udsClient, isNull);
    expect(diagnosticSession.protocolReady, isFalse);

    final ownedSession = diagnosticSession.elmSession!;
    diagnosticSession.detach();
    expect(diagnosticSession.connected, isFalse);
    expect(diagnosticSession.protocolReady, isFalse);
    expect(firstTransport.closed, isFalse);
    await firstElm.close();
    await ownedSession.close();
  });

  test('late voltage response after detach is discarded', () async {
    final transport = _FakeTransport();
    final elm = ElmSession(transport);
    diagnosticSession.attach(elm, voltage: '12.2 V');

    final voltageFuture = diagnosticSession.readAdapterVoltage();
    await Future<void>.delayed(Duration.zero);
    diagnosticSession.detach();
    transport.respond('13.1 V');

    await expectLater(voltageFuture, throwsA(isA<StateError>()));
    expect(diagnosticSession.voltage, isNull);
    await elm.close();
  });
}

class _FakeTransport implements AdapterTransport {
  final _incoming = StreamController<List<int>>();
  bool closed = false;

  @override
  Stream<List<int>> get incoming => _incoming.stream;

  @override
  Future<void> write(List<int> bytes) async {}

  void respond(String value) => _incoming.add(ascii.encode('$value\r>'));

  @override
  Future<void> close() async {
    closed = true;
    await _incoming.close();
  }
}

class _FakeUdsLink implements UdsRequestLink {
  @override
  Future<List<int>> request(List<int> payload, {Duration? timeout}) async =>
      [0x59, 0x02, 0xff];
}
