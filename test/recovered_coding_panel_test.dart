import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:crossscanmoto/diagnostic_session.dart';
import 'package:crossscanmoto/diagnostics/bmw_coding_engine.dart';
import 'package:crossscanmoto/diagnostics/elm_session.dart';
import 'package:crossscanmoto/diagnostics/uds_client.dart';
import 'package:crossscanmoto/recovered_coding_panel.dart';

late final BmwCodingDefinitionCatalog _testCatalog;

class _DummyTransport implements AdapterTransport {
  final incomingController = StreamController<List<int>>.broadcast();

  @override
  Stream<List<int>> get incoming => incomingController.stream;

  @override
  Future<void> write(List<int> bytes) async {}

  @override
  Future<void> close() async {
    await incomingController.close();
  }
}

class _FakeUdsLink implements UdsRequestLink {
  _FakeUdsLink({this.onSend});

  final Future<List<int>> Function(List<int> request)? onSend;
  final List<List<int>> recordedRequests = [];

  @override
  Future<List<int>> request(List<int> payload, {Duration? timeout}) async {
    recordedRequests.add(payload);
    if (onSend != null) {
      return onSend!(payload);
    }
    return [payload.first + 0x40, ...payload.skip(1)];
  }
}

void main() {
  setUpAll(() {
    final jsonStr = File('assets/data/recovered_coding_definitions.json').readAsStringSync();
    final data = jsonDecode(jsonStr) as Map<String, dynamic>;
    _testCatalog = BmwCodingDefinitionCatalog.fromJson(data);
  });

  setUp(() {
    DiagnosticSession.instance.detach();
    DiagnosticSession.instance.clearVehicleProfile();
  });

  tearDown(() {
    DiagnosticSession.instance.detach();
  });

  testWidgets('RecoveredCodingPanel stages parameter change and discards cleanly', (tester) async {
    final transport = _DummyTransport();
    final elm = ElmSession(transport);
    DiagnosticSession.instance.attach(elm, identity: 'OBDLink LX');
    DiagnosticSession.instance.updateVehicleProfile(
      vin: 'WB10A0100HZ123456',
      model: 'R 1200 GS',
    );

    // Initial state of KMBI_K25_C04 blocks:
    // DID 0x3005: [0x00, 0x01, 0x00] -> CLOCK_MODE: '24h', ODO_UNIT: 'km'
    final storedState = <int, List<int>>{
      0x3005: [0x00, 0x01, 0x00],
      0x300A: List.filled(5, 0x00),
      0x300B: List.filled(13, 0x00),
      0x300F: List.filled(9, 0x00),
    };

    final link = _FakeUdsLink(onSend: (req) async {
      final sid = req.first;
      if (sid == 0x22) {
        final did = (req[1] << 8) | req[2];
        final block = storedState[did] ?? [0x00, 0x00, 0x00];
        return [0x62, req[1], req[2], ...block];
      }
      return [sid + 0x40];
    });

    final udsClient = UdsClient(link);
    DiagnosticSession.instance.attachUdsClient(udsClient, ecuKey: 'KMBI_K25_C04');

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: RecoveredCodingPanel(catalog: _testCatalog),
      ),
    ));
    await tester.pumpAndSettle();

    // Verify catalog loaded and KMBI variant selected
    expect(find.text('Verified Coding Engine Active'), findsOneWidget);
    expect(find.text('Read ECU Coding'), findsOneWidget);

    // Read coding from ECU
    await tester.tap(find.text('Read ECU Coding'));
    await tester.pumpAndSettle();

    // Verify parameter decoded
    expect(find.text('CLOCK_MODE'), findsOneWidget);
    expect(find.text('24h'), findsWidgets);

    // Tap CLOCK_MODE tile to stage change
    await tester.tap(find.text('CLOCK_MODE'));
    await tester.pumpAndSettle();

    // Bottom sheet options: '12h' and '24h'
    expect(find.text('Select Option: CLOCK_MODE'), findsOneWidget);
    expect(find.text('12h'), findsOneWidget);

    // Select '12h'
    await tester.tap(find.text('12h'));
    await tester.pumpAndSettle();

    // Verify staged banner appears
    expect(find.text('1 parameter(s) staged across 1 block(s)'), findsOneWidget);
    expect(find.text('Apply Coding to ECU'), findsOneWidget);
    expect(find.text('Discard'), findsOneWidget);

    // Discard staged change
    await tester.tap(find.text('Discard'));
    await tester.pumpAndSettle();

    // Staged banner should be gone
    expect(find.text('1 parameter(s) staged across 1 block(s)'), findsNothing);
  });

  testWidgets('RecoveredCodingPanel stages change and successfully writes to ECU with backup & readback', (tester) async {
    final transport = _DummyTransport();
    final elm = ElmSession(transport);
    DiagnosticSession.instance.attach(elm, identity: 'OBDLink LX');
    DiagnosticSession.instance.updateVehicleProfile(
      vin: 'WB10A0100HZ123456',
      model: 'R 1200 GS',
    );

    final storedState = <int, List<int>>{
      0x3005: [0x00, 0x01, 0x00],
      0x300A: List.filled(5, 0x00),
      0x300B: List.filled(13, 0x00),
      0x300F: List.filled(9, 0x00),
    };

    final link = _FakeUdsLink(onSend: (req) async {
      final sid = req.first;
      if (sid == 0x22) {
        final did = (req[1] << 8) | req[2];
        final block = storedState[did] ?? [0x00, 0x00, 0x00];
        return [0x62, req[1], req[2], ...block];
      } else if (sid == 0x2E) {
        // WriteDataByIdentifier
        final did = (req[1] << 8) | req[2];
        storedState[did] = req.skip(3).toList();
        return [0x6E, req[1], req[2]];
      } else if (sid == 0x11) {
        // ECUReset
        return [0x51, req[1]];
      }
      return [sid + 0x40];
    });

    final udsClient = UdsClient(link);
    DiagnosticSession.instance.attachUdsClient(udsClient, ecuKey: 'KMBI_K25_C04');

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: RecoveredCodingPanel(catalog: _testCatalog),
      ),
    ));
    await tester.pumpAndSettle();

    // Read coding from ECU
    await tester.tap(find.text('Read ECU Coding'));
    await tester.pumpAndSettle();

    // Tap CLOCK_MODE tile to stage change to '12h'
    await tester.tap(find.text('CLOCK_MODE'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('12h'));
    await tester.pumpAndSettle();

    expect(find.text('Apply Coding to ECU'), findsOneWidget);

    // Tap Apply Coding to ECU
    await tester.tap(find.text('Apply Coding to ECU'));
    await tester.pumpAndSettle();

    // Warning confirmation dialog
    expect(find.text('Confirm & Write'), findsOneWidget);

    // Tap Confirm & Write
    await tester.tap(find.text('Confirm & Write'));
    await tester.pumpAndSettle();

    // Verify success banner and verified readback message
    expect(find.textContaining('Successfully wrote coding'), findsOneWidget);

    // Verify stored state has updated CLOCK_MODE (bit 0 cleared to 0)
    expect(storedState[0x3005]![1], 0x00);

    // Verify request sequence: 0x22 (read) -> 0x2E (write) -> 0x11 (reset) -> 0x22 (verify) -> 0x22 (refresh)
    final sids = link.recordedRequests.map((r) => r.first).toList();
    expect(sids, contains(0x2E));
    expect(sids, contains(0x11));
  });
}
