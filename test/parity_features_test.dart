import 'package:flutter_test/flutter_test.dart';
import 'package:crossscanmoto/diagnostics/actuator_manager.dart';
import 'package:crossscanmoto/diagnostics/auto_scan_controller.dart';
import 'package:crossscanmoto/diagnostics/coding_manager.dart';
import 'package:crossscanmoto/diagnostics/dtc_database.dart';
import 'package:crossscanmoto/diagnostics/ecu_catalog.dart';
import 'package:crossscanmoto/diagnostics/live_data_definitions.dart';
import 'package:crossscanmoto/diagnostics/protocol_setup.dart';
import 'package:crossscanmoto/diagnostics/service_manager.dart';
import 'package:crossscanmoto/diagnostics/service_reset_protocol.dart';
import 'package:crossscanmoto/diagnostics/vehicle_catalog.dart';

void main() {
  group('BMW ECU & Vehicle Catalog Parity', () {
    test('contains all primary BMW Motorrad control units', () {
      expect(BmwEcuCatalog.all.length, greaterThanOrEqualTo(8));
      final dme = BmwEcuCatalog.getByAddress(0x12);
      expect(dme, isNotNull);
      expect(dme!.id, 'dme');
      expect(dme.germanAbbrev, contains('DME'));

      final abs = BmwEcuCatalog.getByAddress(0x28);
      expect(abs, isNotNull);
      expect(abs!.id, 'abs');

      final kombi = BmwEcuCatalog.getByAddress(0x60);
      expect(kombi, isNotNull);
      expect(kombi!.id, 'kombi');

      final zfe = BmwEcuCatalog.getByAddress(0x00);
      expect(zfe, isNotNull);
      expect(zfe!.id, 'zfe');
    });

    test('vehicle catalog supports all major BMW series', () {
      expect(BmwVehicleCatalog.models.length, greaterThanOrEqualTo(15));
      final r1250gs = BmwVehicleCatalog.findByName('R 1250 GS');
      expect(r1250gs, isNotNull);
      expect(r1250gs!.seriesCode, 'K50');
      expect(r1250gs.displacementCc, 1254);

      final s1000rr = BmwVehicleCatalog.findByName('S 1000 RR');
      expect(s1000rr, isNotNull);
      expect(s1000rr!.seriesCode, 'K67');

      final f850gs = BmwVehicleCatalog.findByName('F 850 GS');
      expect(f850gs, isNotNull);
      expect(f850gs!.seriesCode, 'K81');
    });

    test('ECU catalog specifies candidate ECU keys for ECU-scoped resolution', () {
      for (final ecu in BmwEcuCatalog.all) {
        expect(ecu.candidateEcuKeys, isNotEmpty,
            reason: '${ecu.id} must define candidate ECU keys');
      }
      expect(BmwEcuCatalog.dme.candidateEcuKeys, contains('cuX_BMSX'));
      expect(BmwEcuCatalog.abs.candidateEcuKeys, contains('cuX_ABS'));
      expect(BmwEcuCatalog.kombi.candidateEcuKeys, contains('cuX_KOMBI'));
    });

    test('vehicle catalog integrates 84 recovered native records and avoids address guessing', () {
      expect(BmwVehicleCatalog.recoveredVehicles.length, 84);
      // Matching by chassis code from 84 recovered entries
      final c1 = BmwVehicleCatalog.identifyFromVin('WB10C010000000000');
      expect(c1, isNotNull);
      expect(c1!.name, 'C1');

      // Generic DME + KOMBI does not falsely guess a specific model
      final inferred = BmwVehicleCatalog.inferModelFromAddresses([0x12, 0x60]);
      expect(inferred, isNull, reason: 'Generic DME+KOMBI bus addresses must not guess a specific model');
    });
  });

  group('BMW DTC Database', () {
    test('uses original ECU-scoped descriptions without guessed repairs', () {
      final abs = BmwDtcDatabase.lookup(25378, ecuKey: 'cuMRABS', defaultEcu: 'ABS');
      expect(abs.title, 'Wheel-speed sensor, front');
      expect(abs.ecuAcronym, 'ABS');
      expect(abs.possibleCauses, 'Not supplied by the diagnostic definition.');
      final unknown = BmwDtcDatabase.lookup(0x999999);
      expect(unknown.standardCode, '0x999999');
      expect(unknown.title, startsWith('Unresolved ECU fault'));
    });

    test('DTC lookup with candidateKeys resolves ECU-scoped text', () {
      final record = BmwDtcDatabase.lookup(
        25378,
        defaultEcu: 'ABS',
        candidateKeys: BmwEcuCatalog.abs.candidateEcuKeys,
      );
      expect(record.title, 'Wheel-speed sensor, front');
      expect(record.ecuAcronym, 'ABS');
    });

    test('parses UDS DTC status mask flags', () {
      const flags = UdsDtcStatusFlags(0x09); // confirmed (8) + testFailed (1)
      expect(flags.confirmedDtc, isTrue);
      expect(flags.testFailed, isTrue);
      expect(flags.pendingDtc, isFalse);
      expect(flags.summary, contains('Confirmed'));
    });
  });

  group('Live Telemetry Definitions', () {
    test('metric to imperial conversion functions accurately', () {
      expect(BmwUnitConverter.toImperial(100, '°C'), closeTo(212, 0.1));
      expect(BmwUnitConverter.toImperial(100, 'km/h'), closeTo(62.14, 0.1));
      expect(BmwUnitConverter.toImperial(2.5, 'bar'), closeTo(36.26, 0.1));
    });
  });

  group('BMW Service Manager', () {
    test('only exposes proven E12x service functions on supported ECU keys',
        () {
      expect(BmwServiceManager.items, isEmpty,
          reason: 'legacy surfaces do not collect ECU key and reset values');
      expect(
          BmwServiceManager.actions.map((item) => item.type),
          containsAll([
            ServiceFunctionType.setVehicleDateTime,
            ServiceFunctionType.setNextServiceDate,
            ServiceFunctionType.setNextServiceMileage,
            ServiceFunctionType.setAllServiceData,
          ]));
      expect(
          BmwServiceManager.supportedEcuKeys,
          unorderedEquals(BmwServiceResetCatalog.supportedUdsEcuKeys));
      expect(BmwServiceManager.supportedEcuKeys, hasLength(12));
      for (final key in [
        'cuX_BMSX',
        'cuX_BMSE2B',
        'cuX_BMSE2',
        'cuX_BMSMP1',
        'cuX_BMSO1',
        'cuX_KOMB',
        'MRKOMB18',
      ]) {
        expect(BmwServiceResetCatalog.supportsEcuKey(key), isFalse);
      }
      expect(
        BmwServiceResetCatalog.addressForEcuKey('cuX_KOMB18'),
        96,
      );
      expect(BmwServiceResetCatalog.addressForEcuKey('cuX_CCP'), 64);
    });

    test('service execution without an explicitly configured link is rejected',
        () async {
      final result = await BmwServiceManager.execute(
        item: BmwServiceManager.actions.first,
        link: null,
        ecuKey: 'cuX_KOMB18',
        vehicleDateTime: DateTime(2026, 10, 31),
        nextServiceDate: DateTime(2027, 10, 31),
        nextServiceMileage: 12000,
      );
      expect(result.success, isFalse);
      expect(result.newServiceDate, isNull);
      expect(result.message, contains('Configure a BMW UDS ECU link'));
    });
  });

  group('Vehicle Coding & Snapshots', () {
    test('modifies coding values and persists snapshots', () {
      final manager = BmwCodingManager();
      expect(manager.currentValues['startup_animation'], 'M Motorsport');

      manager.setValue('startup_animation', 'GS Adventure');
      expect(manager.currentValues['startup_animation'], 'GS Adventure');

      final snapshot = manager.createSnapshot(
        model: 'R 1250 GS',
        vin: 'WB10A0308PZ148291',
      );
      expect(manager.snapshots.length, 1);
      expect(snapshot.values['startup_animation'], 'GS Adventure');

      manager.setValue('startup_animation', 'Standard BMW');
      expect(manager.currentValues['startup_animation'], 'Standard BMW');

      // Restore
      final restored = manager.restoreSnapshot(snapshot.id);
      expect(restored, isTrue);
      expect(manager.currentValues['startup_animation'], 'GS Adventure');
    });
  });

  group('Actuator Manager', () {
    test('defines required component output tests', () {
      expect(BmwActuatorManager.tests.length, greaterThanOrEqualTo(5));
      final fuelPump = BmwActuatorManager.tests.firstWhere(
        (t) => t.type == ActuatorTestType.fuelPump,
      );
      expect(fuelPump.durationSeconds, 5);
      expect(fuelPump.ecuAcronym, 'DME');
    });
  });

  group('AutoScan Controller', () {
    test('offline scan cannot invent responding control units', () async {
      final controller = AutoScanController();
      expect(controller.isScanning, isFalse);

      await controller.runAutoScan(
        session: null,
        adapterType: BmwUdsAdapterType.unknown,
        expectedVin: 'WB10A0308PZ148291',
      );

      expect(controller.isScanning, isFalse);
      expect(controller.totalResponding, 0);
      expect(controller.totalFaults, 0);

      // Clear DME faults
      controller.clearEcuFaults(0x12);
      final dmeReport = controller.reports[0x12];
      expect(dmeReport, isNotNull);
      expect(dmeReport!.dtcs, isEmpty);
      expect(dmeReport.hasFaults, isFalse);
      expect(dmeReport.hasNoReportedFaults, isFalse); // state is pending, not responding
    });

    test('EcuScanReport distinguishes no-reported-faults from health guarantee', () {
      final report = EcuScanReport(
        definition: BmwEcuCatalog.dme,
        state: EcuScanState.responding,
      );
      expect(report.hasFaults, isFalse);
      expect(report.hasNoReportedFaults, isTrue);
      expect(report.isHealthy, isTrue);
    });
  });
}
