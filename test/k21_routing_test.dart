import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:crossscanmoto/diagnostics/auto_scan_controller.dart';
import 'package:crossscanmoto/diagnostics/ecu_catalog.dart';
import 'package:crossscanmoto/diagnostics/elm_session.dart';
import 'package:crossscanmoto/diagnostics/protocol_setup.dart';
import 'package:crossscanmoto/diagnostics/recovered_catalog.dart';
import 'package:crossscanmoto/diagnostic_session.dart';

class _MockTransport implements AdapterTransport {
  final controller = StreamController<List<int>>.broadcast();
  final List<String> writes = [];
  final Queue<String> replies = Queue<String>();

  @override
  Stream<List<int>> get incoming => controller.stream;

  @override
  Future<void> write(List<int> bytes) async {
    final cmd = ascii.decode(bytes).replaceFirst('\r', '');
    writes.add(cmd);
    final reply = replies.isNotEmpty ? replies.removeFirst() : 'NO DATA';
    controller.add(ascii.encode('$reply\r>'));
  }

  @override
  Future<void> close() => controller.close();
}

String _kwpFrame(List<int> payload) {
  final bytes = [payload.length, ...payload, 0];
  return bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    DiagnosticSession.instance.clearVehicleProfile();
  });

  group('K21 Vehicle & ECU Routing Parity', () {
    test('K21 series spans two distinct platforms in recovered native tables', () {
      final vehicles = BmwRawVehicleDatabase.vehiclesForSeries('K21');
      expect(vehicles.length, 2);

      final p1 = vehicles.firstWhere((v) => v['car_platformid'] == '1');
      expect(p1['description'], 'R nineT');

      final p2 = vehicles.firstWhere((v) => v['car_platformid'] == '2');
      expect(p2['description'], 'R nineT MUE');

      expect(BmwRawVehicleDatabase.isAmbiguousSeries('K21'), isTrue);
    });

    test('reconciles exactly six colliding ECU addresses between Platform 1 and 2', () {
      final p1Groups = BmwRawVehicleDatabase.groupsForSeries('K21', platformId: '1');
      final p2Groups = BmwRawVehicleDatabase.groupsForSeries('K21', platformId: '2');

      expect(p1Groups.length, 7);
      expect(p2Groups.length, 16);

      final p1Addrs = p1Groups.map((g) => int.parse(g['defaultaddress']!)).toSet();
      final p2Addrs = p2Groups.map((g) => int.parse(g['defaultaddress']!)).toSet();

      final collidingAddrs = p1Addrs.intersection(p2Addrs);
      expect(collidingAddrs.length, 6);
      expect(collidingAddrs, containsAll([
        18,  // 0x12: DME (D_MRMOT vs G_MRMOT)
        41,  // 0x29: ABS (D_MRABS vs G_MRABS)
        65,  // 0x41: DWA (D_MRDWA vs G_MRDWA)
        96,  // 0x60: KOMBI (D_MRKOMB vs G_MRKOMB)
        99,  // 0x63: AUD / AUDIO (D_MRAUD vs G_MRAUD)
        114, // 0x72: ZFE / GM (D_MRZFE vs G_MRBCO)
      ]));
    });

    test('AutoScanController eliminates collisions using protocol-qualified routing keys', () {
      final controller = AutoScanController();
      final combinedEcus = BmwEcuCatalog.forSeries('K21');

      // 7 from platform 1 + 16 from platform 2 = 23 candidate ECUs
      expect(combinedEcus.length, 23);

      controller.reset(combinedEcus);

      // Verify all 23 reports are retained in reportsByKey without overwriting
      expect(controller.reportsByKey.length, 23);
      expect(controller.reports.length, 23);

      // Verify specific colliding pairs have distinct reports
      final kwpDme = controller.reportForAddress(0x12, isLegacyKwp: true);
      final udsDme = controller.reportForAddress(0x12, isLegacyKwp: false);

      expect(kwpDme, isNotNull);
      expect(udsDme, isNotNull);
      expect(identical(kwpDme, udsDme), isFalse);
      expect(kwpDme!.definition.isLegacyKwp, isTrue);
      expect(udsDme!.definition.isLegacyKwp, isFalse);

      final kwpKombi = controller.reportForAddress(0x60, isLegacyKwp: true);
      final udsKombi = controller.reportForAddress(0x60, isLegacyKwp: false);
      expect(kwpKombi, isNotNull);
      expect(udsKombi, isNotNull);
      expect(identical(kwpKombi, udsKombi), isFalse);
      expect(kwpKombi!.definition.isLegacyKwp, isTrue);
      expect(udsKombi!.definition.isLegacyKwp, isFalse);
    });

    test('reports[int] prioritizes responding ECU at shared address', () {
      final controller = AutoScanController();
      final combinedEcus = BmwEcuCatalog.forSeries('K21');
      controller.reset(combinedEcus);

      // Mark UDS DME as responding
      final udsDme = controller.reportForAddress(0x12, isLegacyKwp: false)!;
      udsDme.state = EcuScanState.responding;
      udsDme.vin = 'WB10J0100HZ123456';

      // Indexing by int address 0x12 returns the responding report
      final report = controller.reports[0x12];
      expect(report, isNotNull);
      expect(report!.state, EcuScanState.responding);
      expect(report.definition.isLegacyKwp, isFalse);
      expect(report.vin, 'WB10J0100HZ123456');
    });

    test('auto-probes and resolves K21 Platform 1 when KWP responds to 0x12', () async {
      final transport = _MockTransport();
      final session = ElmSession(transport);

      // Setup replies:
      // KWP probe: 6 ELM setup commands ("OK"), then startCommunication 0x81 -> positive reply 0xC1
      transport.replies.addAll(List.filled(6, 'OK'));
      transport.replies.add(_kwpFrame([0xc1])); // KWP StartCommunication positive ACK

      // Full scan will then scan only Platform 1 (7 ECUs)
      // DME scan replies:
      transport.replies.addAll(List.filled(6, 'OK'));
      transport.replies.add(_kwpFrame([0xc1])); // startCommunication check
      transport.replies.add(_kwpFrame([0xc1])); // readIdentification 0x90 startComm
      final vinBytes = ascii.encode('WB10A0600HZ123456');
      transport.replies.add(_kwpFrame([0x5a, 0x90, ...vinBytes])); // VIN reply
      transport.replies.add(_kwpFrame([0xc1])); // readIdentification 0x80 startComm
      transport.replies.add(_kwpFrame([0x5a, 0x80, 0x77, 0x28, 0x49])); // ECU ID
      transport.replies.add(_kwpFrame([0xc1])); // readDtc startComm
      transport.replies.add(_kwpFrame([0x58, 0x00])); // No DTCs

      // Other 6 ECUs return NO DATA on startCommunication
      for (var i = 0; i < 6; i++) {
        transport.replies.addAll(List.filled(6, 'OK'));
        transport.replies.add('NO DATA');
      }

      final controller = AutoScanController();
      await controller.runAutoScan(
        session: session,
        adapterType: BmwUdsAdapterType.unknown,
        seriesCode: 'K21',
      );

      expect(controller.detectedPlatformId, '1');
      expect(controller.detectedPlatformName, contains('R nineT'));
      expect(controller.totalResponding, 1);

      final dmeReport = controller.reports[0x12];
      expect(dmeReport, isNotNull);
      expect(dmeReport!.state, EcuScanState.responding);
      expect(dmeReport.vin, 'WB10A0600HZ123456');
      expect(dmeReport.definition.isLegacyKwp, isTrue);

      // Check that the session profile was auto-identified with R nineT (2014–2016)
      expect(DiagnosticSession.instance.profile.modelName, 'R nineT (2014–2016)');
      expect(DiagnosticSession.instance.profile.model?.platformId, '1');
    });

    test('auto-probes and resolves K21 Platform 2 when UDS responds to 0x12', () async {
      final transport = _MockTransport();
      final session = ElmSession(transport);

      // Setup replies:
      // KWP probe fails (NO DATA on startCommunication):
      transport.replies.addAll(List.filled(6, 'OK'));
      transport.replies.add('NO DATA');

      // UDS probe on 0x12:
      // 11 UDS setup commands, then 0xF190 returns VIN
      transport.replies.addAll(List.filled(11, 'OK'));
      transport.replies.add('412001462F190574231304A30313030485A363534333231'); // WB10J0100HZ654321 (0J01 = R nineT MUE)

      // Scan then runs for Platform 2 (16 ECUs):
      // DME UDS replies:
      transport.replies.addAll(List.filled(11, 'OK'));
      transport.replies.add('41200035902FF'); // 0 DTCs
      transport.replies.add('412001462F190574231304A30313030485A363534333231');
      transport.replies.add('412000762F18777284901');
      transport.replies.add('412000B62F1924857203031');
      transport.replies.add('412000B62F1895357203134');
      transport.replies.add('412000862F18A426F736368');

      // Other 15 ECUs return NO DATA
      for (var i = 0; i < 15; i++) {
        transport.replies.addAll(List.filled(11, 'OK'));
        transport.replies.add('NO DATA');
      }

      final controller = AutoScanController();
      await controller.runAutoScan(
        session: session,
        adapterType: BmwUdsAdapterType.unknown,
        seriesCode: 'K21',
      );

      expect(controller.detectedPlatformId, '2');
      expect(controller.detectedPlatformName, contains('R nineT MUE'));
      expect(controller.totalResponding, 1);

      final dmeReport = controller.reports[0x12];
      expect(dmeReport, isNotNull);
      expect(dmeReport!.state, EcuScanState.responding);
      expect(dmeReport.vin, 'WB10J0100HZ654321');
      expect(dmeReport.definition.isLegacyKwp, isFalse);

      // Check that the session profile was auto-identified with R nineT MUE (2017–2023)
      expect(DiagnosticSession.instance.profile.modelName, 'R nineT MUE (2017–2023)');
      expect(DiagnosticSession.instance.profile.model?.platformId, '2');
    });
  });
}
