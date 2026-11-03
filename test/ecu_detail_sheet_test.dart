import 'dart:async';
import 'dart:collection';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:crossscanmoto/diagnostic_session.dart';
import 'package:crossscanmoto/diagnostics/auto_scan_controller.dart';
import 'package:crossscanmoto/diagnostics/dtc_database.dart';
import 'package:crossscanmoto/diagnostics/ecu_catalog.dart';
import 'package:crossscanmoto/diagnostics/elm_session.dart';
import 'package:crossscanmoto/ecu_detail_dialog.dart';

class _MockTransport implements AdapterTransport {
  final incomingController = StreamController<List<int>>.broadcast();
  final writes = <String>[];
  final replies = <String, Queue<String>>{};

  void reply(String command, String response) {
    replies.putIfAbsent(command, Queue.new).add(response);
  }

  @override
  Stream<List<int>> get incoming => incomingController.stream;

  @override
  Future<void> write(List<int> bytes) async {
    final cmd = ascii.decode(bytes).replaceAll('\r', '').trim();
    writes.add(cmd);
    final queue = replies[cmd];
    final res = (queue != null && queue.isNotEmpty) ? queue.removeFirst() : _defaultResponse(cmd);
    incomingController.add(ascii.encode('$res\r>'));
  }

  String _defaultResponse(String cmd) {
    if (cmd.startsWith('AT')) return 'OK';
    if (cmd.startsWith('14')) return '412000154'; // UDS clear DTC positive response: CAN header 412, len 0001, service 54
    if (cmd == '14FFFF') return '015400'; // KWP clear DTC positive frame
    return 'OK';
  }

  @override
  Future<void> close() async {
    await incomingController.close();
  }
}

void main() {
  setUp(() {
    DiagnosticSession.instance.detach();
    DiagnosticSession.instance.clearVehicleProfile();
  });

  tearDown(() {
    DiagnosticSession.instance.detach();
  });

  testWidgets('Overview tab reports correct protocol link based on isLegacyKwp', (tester) async {
    const kwpDef = BmwEcuDefinition(
      id: 'kwp_kombi_0x60',
      name: 'Instrument Cluster',
      germanAbbrev: 'KOMBI',
      description: 'Legacy Cockpit Display',
      category: EcuCategory.cockpit,
      icon: Icons.speed,
      standardUdsAddress: 0x60,
      legacyKwpAddress: 0x80,
      isLegacyKwp: true,
      protocolId: 3,
      candidateEcuKeys: ['MRKOMBI', 'cuMRKOMBI'],
    );
    final kwpReport = EcuScanReport(definition: kwpDef, state: EcuScanState.responding);

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: EcuDetailSheet(report: kwpReport),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('BMW KWP2000 on K-Line (ISO 14230)'), findsOneWidget);
    expect(find.text('BMW UDS on CAN (ISO 14229)'), findsNothing);

    // Now test UDS definition
    const udsDef = BmwEcuDefinition(
      id: 'uds_bmsx_0x12',
      name: 'Engine Management',
      germanAbbrev: 'DME',
      description: 'BMS-X Engine Control',
      category: EcuCategory.powertrain,
      icon: Icons.settings,
      standardUdsAddress: 0x12,
      legacyKwpAddress: 0x12,
      isLegacyKwp: false,
      protocolId: 8,
      candidateEcuKeys: ['cuX_BMSX'],
    );
    final udsReport = EcuScanReport(definition: udsDef, state: EcuScanState.responding);

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: EcuDetailSheet(report: udsReport),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('BMW UDS on CAN (ISO 14229)'), findsOneWidget);
    expect(find.text('BMW KWP2000 on K-Line (ISO 14230)'), findsNothing);
  });

  testWidgets('Faults tab clear DTCs clears fault memory on UDS ECU', (tester) async {
    final transport = _MockTransport();
    final session = ElmSession(transport);
    DiagnosticSession.instance.attach(session, identity: 'OBDLink LX');

    const def = BmwEcuDefinition(
      id: 'uds_bmsx_0x12',
      name: 'Engine Management',
      germanAbbrev: 'DME',
      description: 'BMS-X Engine Control',
      category: EcuCategory.powertrain,
      icon: Icons.settings,
      standardUdsAddress: 0x12,
      legacyKwpAddress: 0x12,
      isLegacyKwp: false,
      protocolId: 8,
      candidateEcuKeys: ['cuX_BMSX'],
    );
    const dtc = BmwDtcRecord(
      code: 0x10001,
      standardCode: '10001',
      ecuAcronym: 'DME',
      title: 'O2 Sensor Signal',
      description: 'O2 Sensor circuit open',
      possibleCauses: 'Wiring harness or sensor failure',
      recommendedAction: 'Check connector',
      statusByte: 0x2F,
    );
    final report = EcuScanReport(
      definition: def,
      state: EcuScanState.responding,
      dtcs: [dtc],
    );

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: EcuDetailSheet(report: report),
      ),
    ));
    await tester.pumpAndSettle();

    // Switch to Faults tab
    await tester.tap(find.text('Faults'));
    await tester.pumpAndSettle();

    expect(find.text('FAULT CODES (1)'), findsOneWidget);
    expect(find.text('O2 Sensor Signal'), findsOneWidget);

    // Tap Clear DTCs button
    await tester.tap(find.text('Clear DTCs'));
    await tester.pumpAndSettle();

    // Verify confirmation dialog mentions UDS service 0x14
    expect(find.text('Clear DME DTCs?'), findsOneWidget);
    expect(find.textContaining('UDS service 0x14'), findsOneWidget);

    // Tap Clear Codes in dialog
    await tester.tap(find.text('Clear Codes'));
    await tester.pumpAndSettle();

    // Verify UDS clear DTC 14FFFFFF was sent
    expect(transport.writes.any((w) => w.contains('14FFFFFF')), isTrue);
    expect(find.textContaining('Fault memory cleared successfully on DME'), findsOneWidget);
    expect(report.dtcs, isEmpty);
    expect(find.text('No Fault Codes Logged'), findsOneWidget);
  });

  testWidgets('Service tab shows non-cluster disclaimer for DME and verified actions for KOMBI', (tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    const dmeDef = BmwEcuDefinition(
      id: 'uds_bmsx_0x12',
      name: 'Engine Management',
      germanAbbrev: 'DME',
      description: 'BMS-X Engine Control',
      category: EcuCategory.powertrain,
      icon: Icons.settings,
      standardUdsAddress: 0x12,
      legacyKwpAddress: 0x12,
      isLegacyKwp: false,
      protocolId: 8,
      candidateEcuKeys: ['cuX_BMSX'],
    );
    final dmeReport = EcuScanReport(definition: dmeDef, state: EcuScanState.responding);

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: EcuDetailSheet(report: dmeReport),
      ),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Service & Adapt'));
    await tester.pumpAndSettle();

    expect(find.text('No Service Routines for DME'), findsOneWidget);
    expect(find.textContaining('managed by the Instrument Cluster module (KOMBI)'), findsOneWidget);

    // Now test KOMBI
    const kombiDef = BmwEcuDefinition(
      id: 'uds_kombi_0x60',
      name: 'Instrument Cluster',
      germanAbbrev: 'KOMBI',
      description: 'TFT Cockpit',
      category: EcuCategory.cockpit,
      icon: Icons.speed,
      standardUdsAddress: 0x60,
      legacyKwpAddress: 0x80,
      isLegacyKwp: false,
      protocolId: 8,
      candidateEcuKeys: ['cuX_KOMBI', 'cuX_KOMB18'],
    );
    final kombiReport = EcuScanReport(definition: kombiDef, state: EcuScanState.responding);

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: EcuDetailSheet(report: kombiReport),
      ),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Service & Adapt'));
    await tester.pumpAndSettle();

    expect(find.text('KOMBI Service Maintenance'), findsOneWidget);
    expect(find.text('Open Workshop Service Reset Tool'), findsOneWidget);
    expect(find.text('Set bike date and time'), findsOneWidget);
    expect(find.text('Set next service date'), findsOneWidget);
    expect(find.text('Set next service mileage'), findsOneWidget);
    expect(find.text('Update all service data'), findsOneWidget);
  });
}
