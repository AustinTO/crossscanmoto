// Copy to crossscanmoto/test/source_anchored_transport_safety_test.dart.
// These are proposed RED tests against the HEAD inspected on 2026-11-03.
// They are intentionally expected to expose failures until production fixes land.
import 'dart:async';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:crossscanmoto/diagnostic_session.dart';
import 'package:crossscanmoto/diagnostics/auto_scan_controller.dart';
import 'package:crossscanmoto/diagnostics/ecu_catalog.dart';
import 'package:crossscanmoto/diagnostics/elm_session.dart';
import 'package:crossscanmoto/diagnostics/kwp_client.dart';
import 'package:crossscanmoto/diagnostics/protocol_setup.dart';

class _SetupTransport implements AdapterTransport {
  _SetupTransport(this.firstReply);
  final String firstReply;
  final _controller = StreamController<List<int>>.broadcast();
  int sent = 0;

  @override
  Stream<List<int>> get incoming => _controller.stream;

  @override
  Future<void> write(List<int> bytes) async {
    sent++;
    final reply = sent == 1 ? firstReply : 'OK';
    _controller.add(ascii.encode('$reply\r>'));
  }

  @override
  Future<void> close() => _controller.close();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('UDS adapter setup must reject NOT OK, not substring-match OK', () async {
    final transport = _SetupTransport('NOT OK');
    final session = ElmSession(transport);
    expect(await BmwBikeUdsLink(session).configure(id: 0x12), isFalse);
    await session.close();
  });

  test('KWP adapter setup must reject NOT OK, not substring-match OK', () async {
    final transport = _SetupTransport('NOT OK');
    final session = ElmSession(transport);
    expect(await BmwBikeKwpLink(session).configure(ecuAddress: 0x12), isFalse);
    await session.close();
  });

  test('ELM indexed UDS responses must reject missing consecutive index', () {
    expect(
      () => BmwBikeUdsLink.decodeSingleTokenResponse(
        ['0: 62 F1 90 31', '2: 32 33'],
      ),
      throwsFormatException,
    );
  });

  test('Unknown native protocol must NOT silently become UDS', () {
    expect(
      () => BmwEcuCatalog.forGroups([
        {'controlmoduletype': 'DME', 'modulegroup': 'test',
         'defaultprotocolid': '999', 'defaultaddress': '18'},
      ]),
      throwsA(isA<FormatException>()),
    );
  });

  test('Malformed ECU address must NOT silently target engine 0x12', () {
    expect(
      () => BmwEcuCatalog.forGroups([
        {'controlmoduletype': 'DME', 'modulegroup': 'test',
         'defaultprotocolid': '8', 'defaultaddress': 'INVALID'},
      ]),
      throwsA(isA<FormatException>()),
    );
  });

  test('Missing series groups returns empty list, failing closed', () {
    expect(BmwEcuCatalog.forSeries('NONEXISTENT_SERIES_XYZ'), isEmpty);
  });

  test('AutoScanController fails closed when profile has no series code', () async {
    final controller = AutoScanController();
    final transport = _SetupTransport('OK');
    final session = ElmSession(transport);
    await controller.runAutoScan(
      session: session,
      adapterType: BmwUdsAdapterType.obdLinkLx,
      seriesCode: null,
    );
    expect(controller.reports, isEmpty);
    await session.close();
  });

  test('Raw traffic debug logging opt-in captures AT frames and redacts when off', () async {
    final transport = _SetupTransport('OK');
    final session = ElmSession(transport);
    final diag = DiagnosticSession.instance;
    diag.clearTrafficLogs();

    diag.debugLogging = false;
    diag.attach(session, identity: 'TestAdapter');
    await session.command('ATI');
    expect(diag.rawTrafficLogs, isEmpty);

    diag.debugLogging = true;
    await session.command('ATRV');
    expect(diag.rawTrafficLogs, isNotEmpty);
    expect(diag.rawTrafficLogs.any((l) => l.contains('TX: ATRV')), isTrue);
    diag.detach();
    await session.close();
  });

  test('WakeLock handler triggers on attach, detach, and toggle', () {
    final events = <bool>[];
    DiagnosticSession.wakeLockHandler = events.add;
    final diag = DiagnosticSession.instance;
    diag.keepScreenAwake = true;

    final transport = _SetupTransport('OK');
    final session = ElmSession(transport);

    diag.attach(session, identity: 'TestAdapter');
    expect(events.last, isTrue);

    diag.keepScreenAwake = false;
    expect(events.last, isFalse);

    diag.keepScreenAwake = true;
    expect(events.last, isTrue);

    diag.detach();
    expect(events.last, isFalse);
    DiagnosticSession.wakeLockHandler = null;
  });
}
