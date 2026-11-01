import 'dart:async';
import 'dart:convert';

import '../lib/diagnostics/elm_session.dart';
import '../lib/diagnostics/protocol_setup.dart';

class ScriptedTransport implements AdapterTransport {
  ScriptedTransport({this.replies = const {}, this.failures = const {}});

  final Map<String, String> replies;
  final Set<String> failures;
  final writes = <String>[];
  final _incoming = StreamController<List<int>>();

  @override
  Stream<List<int>> get incoming => _incoming.stream;

  @override
  Future<void> write(List<int> bytes) async {
    final command = ascii.decode(bytes).trim();
    writes.add(command);
    final fallback = command == '22F190' ? 'X11220362F190' : 'OK';
    final reply =
        failures.contains(command) ? '?' : (replies[command] ?? fallback);
    scheduleMicrotask(() => _incoming.add(ascii.encode('$reply\r>')));
  }

  @override
  Future<void> close() => _incoming.close();
}

void check(bool value, String message) {
  if (!value) throw StateError(message);
}

Future<void> main() async {
  final transport = ScriptedTransport();
  final session = ElmSession(transport);
  final link =
      BmwBikeUdsLink(session, adapterType: BmwUdsAdapterType.obdLinkMxPlus);
  check(await link.configure(id: 0xf1), 'BMW UDS setup failed');
  check(
    transport.writes.take(11).join(',') ==
        'ATSPB,ATPBC101,ATSH6F1,ATFCSH6F1,ATFCSDf1300008,ATFCSM1,ATCEAf1,ATCM7FF,ATCF6f1,ATST90,ATBI',
    'BMW UDS setup command sequence changed',
  );
  check(
    transport.writes.skip(11).join(',') ==
        'STCSEGT1,STCFCPC,STCFCPA 6F1f1,6f1F3',
    'Supported adapter guard did not issue its exact extension commands',
  );
  check(await link.configure(id: 0xf1), 'Repeated selection should be cached');
  check(
      transport.writes.length == 14, 'Cached selection resent setup commands');

  final reply = await link
      .request([0x22, 0xf1, 0x90], timeout: const Duration(seconds: 2));
  check(transport.writes.last == '22F190',
      'Payload was not sent as uppercase hex');
  check(
      reply.join(',') == '98,241,144', 'UDS application payload decode failed');
  await session.close();

  final unsupportedAdapterTransport = ScriptedTransport();
  final unsupportedAdapterSession = ElmSession(unsupportedAdapterTransport);
  final unsupportedAdapterLink = BmwBikeUdsLink(
    unsupportedAdapterSession,
    adapterType: BmwUdsAdapterType.viaKenStn1170,
  );
  check(await unsupportedAdapterLink.configure(id: 0x100),
      'Base setup should succeed without optional STN extensions');
  check(
    unsupportedAdapterTransport.writes.join(',') ==
        'ATSPB,ATPBC101,ATSH6F1,ATFCSH6F1,ATFCSD100300008,ATFCSM1,ATCEA100,ATCM7FF,ATCF6100,ATST90,ATBI',
    'Unsupported adapter was incorrectly given guarded STN commands or id was truncated',
  );
  await unsupportedAdapterSession.close();

  final failureTransport = ScriptedTransport(replies: const {'ATSH6F1': ''});
  final failureSession = ElmSession(failureTransport);
  final failureLink = BmwBikeUdsLink(failureSession);
  check(!await failureLink.configure(id: 0xf1),
      'Failed required setup command was accepted');
  check(failureTransport.writes.join(',') == 'ATSPB,ATPBC101,ATSH6F1',
      'Setup continued after a failed required command');
  check(!failureLink.isConfigured, 'Failed setup marked link configured');
  await failureSession.close();

  check(
    BmwBikeUdsLink.decodeSingleTokenResponse(['X11220362F190']).join(',') ==
        '98,241,144',
    'Synthetic recorded-format token did not decode',
  );
  for (final malformed in <List<String>>[
    const [],
    const ['X11220362F190', 'Y11220362F190'],
    const ['X11220362F1'],
    const ['X1122GG62F190'],
  ]) {
    try {
      BmwBikeUdsLink.decodeSingleTokenResponse(malformed);
      throw StateError('Malformed/multiline UDS token accepted');
    } on FormatException {
      // Only the recovered single-token frame shape is supported.
    }
  }

  final pendingTransport = ScriptedTransport(replies: const {
    '22F190': 'X1122037F2278',
  });
  final pendingSession = ElmSession(pendingTransport);
  final pendingLink = BmwBikeUdsLink(pendingSession);
  check(await pendingLink.configure(id: 0xf1), 'Pending fixture setup failed');
  try {
    await pendingLink.request([0x22, 0xf1, 0x90]);
    throw StateError('Unsupported pending response was accepted');
  } on FormatException catch (error) {
    check(error.message.toString().contains('pending'),
        'Pending response was rejected without explaining the limitation');
  }
  check(pendingTransport.writes.last == '22F190',
      'Pending response incorrectly caused a request resend');
  await pendingSession.close();

  // ignore: avoid_print
  print(
      'PASS: BMW UDS command order, adapter guards, identifier formatting and payload transport');
}
