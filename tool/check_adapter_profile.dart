import 'dart:async';
import 'dart:convert';

import '../lib/diagnostics/adapter_profile.dart';
import '../lib/diagnostics/elm_session.dart';

class ScriptedTransport implements AdapterTransport {
  ScriptedTransport(this.replies);

  final Map<String, String> replies;
  final writes = <String>[];
  final _incoming = StreamController<List<int>>();

  @override
  Stream<List<int>> get incoming => _incoming.stream;

  @override
  Future<void> write(List<int> bytes) async {
    final command = ascii.decode(bytes).trim();
    writes.add(command);
    final reply = replies[command] ?? '?';
    scheduleMicrotask(() => _incoming.add(ascii.encode('$reply\r>')));
  }

  @override
  Future<void> close() => _incoming.close();
}

void check(bool condition, String message) {
  if (!condition) throw StateError(message);
}

Future<void> main() async {
  final initTransport = ScriptedTransport(const {
    'ATWS': 'ELM327 v1.5',
    'ATL0': 'OK',
    'ATSP0': 'OK',
    'ATH1': 'OK',
    'ATE0': 'OK',
    'ATS0': 'OK',
  });
  final initSession = ElmSession(initTransport);
  final initialized = await initializeCommonAdapter(initSession);
  check(
    initTransport.writes.join(',') == 'ATWS,ATWS,ATL0,ATSP0,ATH1,ATE0,ATS0',
    'Common reset command ordering differs from the traced call path',
  );
  check(initialized.length == 7, 'Initialization responses were not retained');
  await initSession.close();

  final delays = <Duration>[];
  final fullInitializationTransport = ScriptedTransport(const {
    'ATWS': 'ELM327 v1.5',
    'ATL0': 'OK',
    'ATSP0': 'OK',
    'ATH1': 'OK',
    'ATE0': 'OK',
    'ATS0': 'OK',
    'ATI': 'ELM327 v1.5',
    'AT#1': '?',
    'STDI': 'Generic serial adapter',
    'AT@1': 'Generic adapter',
    'ATRV': '12.6V',
  });
  final fullInitializationSession = ElmSession(fullInitializationTransport);
  final fullInitialization = await initializeAdapter(
    fullInitializationSession,
    delay: (duration) async => delays.add(duration),
  );
  check(delays.join(',') == '0:00:02.000000,0:00:02.000000',
      'Post-identification settle timing changed');
  check(fullInitialization.voltage.text == '12.6V', 'ATRV result was lost');
  check(fullInitializationTransport.writes.last == 'ATRV',
      'ATRV was not queried after two seconds');
  await fullInitializationSession.close();

  final wgTransport = ScriptedTransport(const {
    'ATI': 'ELM327 v1.5',
    'AT#1': 'WGSoft UCSI',
    'AT@1': '?', // Unsupported optional response must be retained.
  });
  final wgSession = ElmSession(wgTransport);
  final wg = await identifyAdapter(wgSession);
  check(wg.vendor == AdapterVendor.wgSoft, 'WGSoft branch not identified');
  check(wg.atAt1?.isError == true, 'Unsupported optional reply was discarded');
  check(wg.atHash1 != null && wg.stdi == null, 'Wrong WGSoft branch commands');
  check(wgTransport.writes.join(',') == 'ATI,AT#1,AT@1',
      'Unexpected WGSoft commands');
  await wgSession.close();

  final otherTransport = ScriptedTransport(const {
    'ATI': 'ELM327 compatible',
    'AT#1': '?',
    'STDI': 'Generic serial adapter',
    'AT@1': 'Generic description',
  });
  final otherSession = ElmSession(otherTransport);
  final other = await identifyAdapter(otherSession);
  check(other.vendor == AdapterVendor.other,
      'STDI fallback branch not identified');
  check(other.atHash1?.isError == true, 'Unsupported AT#1 reply was discarded');
  check(otherTransport.writes.join(',') == 'ATI,AT#1,STDI,AT@1',
      'Unexpected fallback commands');
  await otherSession.close();

  final unsupportedTransport = ScriptedTransport(const {'ATI': '?'});
  final unsupportedSession = ElmSession(unsupportedTransport);
  final unsupported = await identifyAdapter(unsupportedSession);
  check(unsupported.vendor == AdapterVendor.unknown,
      'ATI gate did not stop identification');
  check(unsupportedTransport.writes.join(',') == 'ATI',
      'Commands ran after ATI gate failed');
  await unsupportedSession.close();

  // ignore: avoid_print
  print(
      'PASS: traced initialization order, identification branches, optional errors');
}
