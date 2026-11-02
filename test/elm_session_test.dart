import 'dart:async';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:crossscanmoto/diagnostics/elm_session.dart';

class FakeTransport implements AdapterTransport {
  final controller = StreamController<List<int>>();
  final writes = <String>[];
  @override
  Stream<List<int>> get incoming => controller.stream;
  @override
  Future<void> write(List<int> bytes) async => writes.add(ascii.decode(bytes));
  void receive(String value) => controller.add(ascii.encode(value));
  @override
  Future<void> close() => controller.close();
}
void main() {
  test('fragmented prompt response strips echo and serializes commands', () async {
    final transport = FakeTransport(); final session = ElmSession(transport);
    final first = session.command('ATI'); final second = session.command('ATRV');
    await Future<void>.delayed(Duration.zero);
    expect(transport.writes, ['ATI\r']);
    transport.receive('ATI\rELM'); transport.receive('327\r>');
    expect((await first).text, 'ELM327');
    await Future<void>.delayed(Duration.zero);
    expect(transport.writes, ['ATI\r', 'ATRV\r']);
    transport.receive('12.6V\r>');
    expect((await second).text, '12.6V'); await session.close();
  });
  test('timeout prevents late response from being used by next request', () async {
    final transport = FakeTransport(); final session = ElmSession(transport);
    await expectLater(session.command('ATI', timeout: const Duration(milliseconds: 5)), throwsA(isA<TimeoutException>()));
    transport.receive('ELM327\r>');
    await expectLater(session.command('ATRV'), throwsStateError);
    expect(transport.writes, ['ATI\r']); await session.close();
  });
  test('a stalled write obeys the command deadline and rejects queued work', () async {
    final transport = _StalledTransport();
    final session = ElmSession(transport);
    await expectLater(session.command('ATI', timeout: const Duration(milliseconds: 10)),
        throwsA(isA<TimeoutException>()));
    await expectLater(session.command('ATRV'), throwsStateError);
    transport.writeCompletion.complete();
    await session.close();
  });
  test('disconnect fails current request', () async {
    final transport = FakeTransport(); final session = ElmSession(transport);
    final pending = session.command('ATI');
    final expectation = expectLater(pending, throwsStateError);
    await Future<void>.delayed(Duration.zero); await transport.close();
    await expectation; await session.close();
  });
}

class _StalledTransport extends FakeTransport {
  final writeCompletion = Completer<void>();
  @override
  Future<void> write(List<int> bytes) => writeCompletion.future;
}
