import 'dart:async';
import 'dart:collection';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:crossscanmoto/diagnostics/auto_scan_controller.dart';
import 'package:crossscanmoto/diagnostics/ecu_catalog.dart';
import 'package:crossscanmoto/diagnostics/elm_session.dart';
import 'package:crossscanmoto/diagnostics/protocol_setup.dart';

class _ScriptedTransport implements AdapterTransport {
  final controller = StreamController<List<int>>();
  final writes = <String>[];
  final replies = Queue<String>();

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
  group('AutoScan Vehicle Routing & Dual Protocol Parity', () {
    test('routes legacy KWP vehicle platform through KwpClient and reads identification and DTCs', () async {
      final transport = _ScriptedTransport();
      final session = ElmSession(transport);

      // We scan C01 (C1: 3 KWP ECUs: DME 0x12, ABS 0x28, ABS 0x29)
      final c01Ecus = BmwEcuCatalog.forSeries('C01');
      expect(c01Ecus.length, 3);
      expect(c01Ecus.every((e) => e.isLegacyKwp), isTrue);

      // Replies for ECU 1 (DME 0x12):
      // 1-6: KWP setup commands
      transport.replies.addAll(List.filled(6, 'OK'));
      // 7: Responsiveness check: StartCommunication (81)
      transport.replies.add(_kwpFrame([0xc1]));
      // 8-9: ReadIdentification 0x90 (VIN) -> StartCommunication (81) + 1A90
      transport.replies.add(_kwpFrame([0xc1]));
      final vinBytes = ascii.encode('WB10C010000000000');
      transport.replies.add(_kwpFrame([0x5a, 0x90, ...vinBytes]));
      // 10-11: ReadIdentification 0x80 (ECU ID) -> StartCommunication (81) + 1A80
      transport.replies.add(_kwpFrame([0xc1]));
      transport.replies.add(_kwpFrame([0x5a, 0x80, 0x77, 0x28, 0x49]));
      // 12-13: ReadDtc (1802FFFF) -> StartCommunication (81) + 1802FFFF -> 1 DTC: code 4192 (0x1060) status 0x28
      transport.replies.add(_kwpFrame([0xc1]));
      transport.replies.add(_kwpFrame([0x58, 0x01, 0x10, 0x60, 0x28]));

      // Replies for ECU 2 (ABS 0x28) and ECU 3 (ABS 0x29) will return NO DATA on startCommunication
      transport.replies.addAll(List.filled(6, 'OK'));
      transport.replies.add('NO DATA');
      transport.replies.addAll(List.filled(6, 'OK'));
      transport.replies.add('NO DATA');

      final controller = AutoScanController();
      await controller.runAutoScan(
        session: session,
        adapterType: BmwUdsAdapterType.unknown,
        seriesCode: 'C01',
      );

      expect(controller.isScanning, isFalse);
      expect(controller.totalResponding, 1);
      expect(controller.totalFaults, 1);

      final dmeReport = controller.reports[0x12];
      expect(dmeReport, isNotNull);
      expect(dmeReport!.state, EcuScanState.responding);
      expect(dmeReport.vin, 'WB10C010000000000');
      expect(dmeReport.partNumber, '772849');
      expect(dmeReport.dtcs.length, 1);
      expect(dmeReport.dtcs.first.code, 0x1060);
      expect(dmeReport.dtcs.first.title, 'Electric fuel pump');
      expect(dmeReport.dtcs.first.statusByte, 0x28);

      // Verify that KWP commands were sent (ATPC, ATAL, 1A90, 1A80, 1802FFFF)
      expect(transport.writes, contains('1A90'));
      expect(transport.writes, contains('1A80'));
      expect(transport.writes, contains('1802FFFF'));

      await session.close();
    });

    test('routes modern UDS vehicle platform through UdsClient and reads all identification DIDs', () async {
      final transport = _ScriptedTransport();
      final session = ElmSession(transport);

      // We scan R 1250 GS (K50: 16 UDS ECUs)
      final k50Ecus = BmwEcuCatalog.forSeries('K50');
      expect(k50Ecus.length, 16);
      expect(k50Ecus.every((e) => !e.isLegacyKwp), isTrue);

      // Setup controller with just DME for focused testing
      final controller = AutoScanController();

      // Replies for DME 0x12:
      // 11 UDS setup commands: ATSPB, ATPBC101, ATSH6F1, ATFCSH6F1, ATFCSD12300008, ATFCSM1, ATCEA12, ATCM7FF, ATCF612, ATST90, ATBI
      transport.replies.addAll(List.filled(11, 'OK'));
      // Read DTCs 1902FF -> 1 DTC: 0x001131 with status 0x29 (7 bytes payload)
      transport.replies.add('41200075902FF00113129');
      // Read VIN 0xF190 -> WB10J9100KZ123456
      final vinAscii = 'WB10J9100KZ123456';
      final vinHex = ascii.encode(vinAscii).map((b) => b.toRadixString(16).padLeft(2, '0')).join().toUpperCase();
      transport.replies.add('412001462F190$vinHex');
      // Read Part Number 0xF187 -> 77284901
      transport.replies.add('412000762F18777284901');
      // Read HW Version 0xF192 -> HW 03.10
      final hwHex = ascii.encode('HW 03.10').map((b) => b.toRadixString(16).padLeft(2, '0')).join().toUpperCase();
      transport.replies.add('412000B62F192$hwHex');
      // Read SW Version 0xF189 -> SW 14.02
      final swHex = ascii.encode('SW 14.02').map((b) => b.toRadixString(16).padLeft(2, '0')).join().toUpperCase();
      transport.replies.add('412000B62F189$swHex');
      // Read Supplier 0xF18A -> Bosch
      final suppHex = ascii.encode('Bosch').map((b) => b.toRadixString(16).padLeft(2, '0')).join().toUpperCase();
      transport.replies.add('412000862F18A$suppHex');

      await controller.runAutoScan(
        session: session,
        adapterType: BmwUdsAdapterType.unknown,
        targetEcus: [BmwEcuCatalog.dme],
      );

      final dmeReport = controller.reports[0x12];
      expect(dmeReport, isNotNull);
      expect(dmeReport!.state, EcuScanState.responding);
      expect(dmeReport.vin, 'WB10J9100KZ123456');
      expect(dmeReport.partNumber, '77284901');
      expect(dmeReport.hardwareVersion, 'HW 03.10');
      expect(dmeReport.softwareVersion, 'SW 14.02');
      expect(dmeReport.supplierName, 'Bosch');
      expect(dmeReport.dtcs.length, 1);
      expect(dmeReport.dtcs.first.statusByte, 0x29);
      expect(dmeReport.dtcs.first.statusSummary, contains('Confirmed'));

      // Verify that UDS commands were sent
      expect(transport.writes, contains('1902FF'));
      expect(transport.writes, contains('22F190'));
      expect(transport.writes, contains('22F187'));
      expect(transport.writes, contains('22F192'));
      expect(transport.writes, contains('22F189'));
      expect(transport.writes, contains('22F18A'));

      await session.close();
    });
  });
}
