import 'dart:async';
import 'package:flutter/foundation.dart';

import 'dtc_database.dart';
import 'ecu_catalog.dart';
import 'elm_session.dart';
import 'protocol_setup.dart';
import 'uds_client.dart';
import 'vehicle_catalog.dart';
import '../diagnostic_session.dart';

/// State of an individual control unit during and after an auto-scan.
enum EcuScanState {
  pending,
  scanning,
  responding,
  noResponse,
  error,
}

/// Discovered diagnostics result for a specific control unit.
class EcuScanReport {
  EcuScanReport({
    required this.definition,
    required this.state,
    this.vin,
    this.partNumber,
    this.hardwareVersion,
    this.softwareVersion,
    this.supplierName,
    this.dtcs = const [],
    this.statusMessage,
  });

  final BmwEcuDefinition definition;
  EcuScanState state;
  String? vin;
  String? partNumber;
  String? hardwareVersion;
  String? softwareVersion;
  String? supplierName;
  List<BmwDtcRecord> dtcs;
  String? statusMessage;

  bool get hasFaults => dtcs.isNotEmpty;
  bool get isHealthy => state == EcuScanState.responding && dtcs.isEmpty;
}

/// Coordinates full vehicle scan across all BMW Motorrad control units.
class AutoScanController extends ChangeNotifier {
  AutoScanController();

  final Map<int, EcuScanReport> _reports = {};
  bool _isScanning = false;
  double _progress = 0.0;
  String _currentStep = 'Ready';
  bool _cancelled = false;

  Map<int, EcuScanReport> get reports => Map.unmodifiable(_reports);
  bool get isScanning => _isScanning;
  double get progress => _progress;
  String get currentStep => _currentStep;

  int get totalResponding => _reports.values
      .where((r) => r.state == EcuScanState.responding)
      .length;

  int get totalFaults =>
      _reports.values.fold(0, (sum, report) => sum + report.dtcs.length);

  void reset() {
    _reports.clear();
    for (final ecu in BmwEcuCatalog.all) {
      _reports[ecu.standardUdsAddress] = EcuScanReport(
        definition: ecu,
        state: EcuScanState.pending,
      );
    }
    _progress = 0.0;
    _currentStep = 'Ready';
    notifyListeners();
  }

  void cancel() {
    _cancelled = true;
  }

  /// Runs full automatic vehicle scan.
  Future<void> runAutoScan({
    required ElmSession? session,
    required BmwUdsAdapterType adapterType,
    String? expectedVin,
  }) async {
    if (_isScanning) return;
    if (session == null) {
      reset();
      _currentStep = 'Connect an adapter before scanning';
      notifyListeners();
      return;
    }
    _isScanning = true;
    _cancelled = false;
    reset();

    final ecus = BmwEcuCatalog.all;
    final total = ecus.length;

    for (var i = 0; i < total; i++) {
      if (_cancelled) break;
      final ecu = ecus[i];
      final report = _reports[ecu.standardUdsAddress]!;
      report.state = EcuScanState.scanning;
      _currentStep = 'Querying ${ecu.germanAbbrev} (${ecu.name})…';
      _progress = i / total;
      notifyListeners();

      {
        // Physical connection path using BmwBikeUdsLink
        try {
          final link = BmwBikeUdsLink(session, adapterType: adapterType);
          final configured = await link.configure(id: ecu.standardUdsAddress);
          if (configured) {
            final client = UdsClient(link, timeout: const Duration(milliseconds: 900));
            // Read DTCs
            try {
              final dtcReport = await client.readDtcByStatusMask(0xFF);
              report.dtcs = dtcReport.dtcs
                  .map((d) => BmwDtcDatabase.lookup(d.code, defaultEcu: ecu.germanAbbrev))
                  .toList();
              report.state = EcuScanState.responding;
            } catch (error) {
              report.state = EcuScanState.error;
              report.statusMessage = 'Fault-code read failed: $error';
            }

            // Read VIN DID 0xF190
            try {
              final vinBytes = await client.readDataByIdentifier(0xF190);
              report.vin = String.fromCharCodes(vinBytes.where((c) => c >= 32 && c <= 126));
            } catch (_) {
              report.vin = null;
            }

            // Read Part Number DID 0xF187
            try {
              final partBytes = await client.readDataByIdentifier(0xF187);
              report.partNumber = partBytes
                  .map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase())
                  .join();
            } catch (_) {
              report.partNumber = null;
            }
          } else {
            report.state = EcuScanState.noResponse;
          }
        } catch (_) {
          // If query fails or timed out on this bus address
          report.state = EcuScanState.noResponse;
        }
      }

      _progress = (i + 1) / total;
      notifyListeners();
    }

    _isScanning = false;
    _currentStep = _cancelled
        ? 'Scan stopped'
        : 'Scan complete ($totalResponding ECUs responding, $totalFaults fault codes)';

    // Automated Model & Subsystem Identification
    if (!_cancelled && totalResponding > 0) {
      final validVinReport = _reports.values
          .where((r) => r.vin != null && r.vin!.length >= 10)
          .firstOrNull;
      final vin = validVinReport?.vin;
      final detected =
          vin != null ? BmwVehicleCatalog.identifyFromVin(vin) : null;
      final year =
          vin != null ? BmwVehicleCatalog.decodeModelYear(vin) : null;
      final inferred = detected ??
          BmwVehicleCatalog.inferModelFromAddresses(
            _reports.entries
                .where((e) => e.value.state == EcuScanState.responding)
                .map((e) => e.key),
          );

      if (inferred != null) {
        DiagnosticSession.instance.updateVehicleProfile(
          model: inferred.name,
          year: year ?? inferred.startYear,
          vin: vin,
          autoIdentified: true,
        );
      } else if (vin != null) {
        DiagnosticSession.instance.updateVehicleProfile(
          vin: vin,
          year: year,
          autoIdentified: true,
        );
      }
    }

    notifyListeners();
  }

  void clearEcuFaults(int address) {
    final report = _reports[address];
    if (report != null) {
      report.dtcs = [];
      notifyListeners();
    }
  }
}
