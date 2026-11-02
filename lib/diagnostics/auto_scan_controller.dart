import 'dart:async';
import 'package:flutter/foundation.dart';

import 'dtc_database.dart';
import 'ecu_catalog.dart';
import 'elm_session.dart';
import 'kwp_client.dart';
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
  bool get hasNoReportedFaults => state == EcuScanState.responding && dtcs.isEmpty;
  @Deprecated('Use hasNoReportedFaults; absence of returned DTCs does not prove complete vehicle health.')
  bool get isHealthy => hasNoReportedFaults;
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

  void reset([List<BmwEcuDefinition>? ecus]) {
    _reports.clear();
    final targets = ecus ?? BmwEcuCatalog.all;
    for (final ecu in targets) {
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
  ///
  /// Dynamically targets the vehicle's authentic ECU groups and protocol
  /// (UDS on CAN or legacy KWP2000) based on recovered MotoScan platform data.
  Future<void> runAutoScan({
    required ElmSession? session,
    required BmwUdsAdapterType adapterType,
    String? expectedVin,
    String? seriesCode,
    List<BmwEcuDefinition>? targetEcus,
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

    // 1. Resolve vehicle platform and ECU targets
    final effectiveSeries = seriesCode ??
        DiagnosticSession.instance.profile.model?.seriesCode;

    List<BmwEcuDefinition> ecus;
    if (targetEcus != null && targetEcus.isNotEmpty) {
      ecus = targetEcus;
    } else if (effectiveSeries != null) {
      ecus = BmwEcuCatalog.forSeries(effectiveSeries);
    } else {
      ecus = BmwEcuCatalog.all;
    }

    reset(ecus);
    final total = ecus.length;

    for (var i = 0; i < total; i++) {
      if (_cancelled) break;
      final ecu = ecus[i];
      final report = _reports[ecu.standardUdsAddress]!;
      report.state = EcuScanState.scanning;
      _currentStep = 'Querying ${ecu.germanAbbrev} (${ecu.name}) via ${ecu.isLegacyKwp ? "KWP" : "UDS"}…';
      _progress = i / total;
      notifyListeners();

      if (ecu.isLegacyKwp) {
        // Legacy KWP2000 diagnostic scan
        try {
          final kwpLink = BmwBikeKwpLink(session);
          final configured = await kwpLink.configure(ecuAddress: ecu.legacyKwpAddress);
          if (configured) {
            // Check responsiveness before issuing full queries
            final isAlive = await () async {
              try {
                return await kwpLink.startCommunication();
              } catch (_) {
                return false;
              }
            }();

            if (!isAlive) {
              report.state = EcuScanState.noResponse;
              continue;
            }

            final client = KwpClient(kwpLink);

            // Read KWP Identification (Service 0x1A 0x90 = VIN)
            try {
              final vinBytes = await client.readIdentification(0x90);
              final vinStr = String.fromCharCodes(vinBytes.where((c) => c >= 32 && c <= 126)).trim();
              if (vinStr.isNotEmpty) report.vin = vinStr;
            } catch (_) {
              report.vin = null;
            }

            // Read KWP ECU Identification (Service 0x1A 0x80 = Standard ECU ID)
            try {
              final idBytes = await client.readIdentification(0x80);
              if (idBytes.isNotEmpty) {
                final partBytes = idBytes.first == 0x80 ? idBytes.skip(1) : idBytes;
                report.partNumber = partBytes
                    .map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase())
                    .join();
              }
            } catch (_) {
              // Standard ID not returned
            }

            // Read DTCs via Service 0x18
            try {
              final dtcReport = await client.readDtc();
              report.dtcs = dtcReport.dtcs
                  .map((d) => BmwDtcDatabase.lookup(
                        d.code,
                        defaultEcu: ecu.germanAbbrev,
                        candidateKeys: ecu.candidateEcuKeys,
                        statusByte: d.opaqueRecordByte,
                        isUds: false,
                      ))
                  .toList();
              report.state = EcuScanState.responding;
            } catch (error) {
              report.state = EcuScanState.error;
              report.statusMessage = 'KWP fault-code read failed: $error';
            }
          } else {
            report.state = EcuScanState.noResponse;
          }
        } catch (_) {
          report.state = EcuScanState.noResponse;
        }
      } else {
        // Modern UDS on CAN diagnostic scan
        try {
          final udsLink = BmwBikeUdsLink(session, adapterType: adapterType);
          final configured = await udsLink.configure(id: ecu.standardUdsAddress);
          if (configured) {
            final client = UdsClient(udsLink, timeout: const Duration(milliseconds: 900));

            // Read DTCs via UDS Service 0x19 0x02
            try {
              final dtcReport = await client.readDtcByStatusMask(0xFF);
              report.dtcs = dtcReport.dtcs
                  .map((d) => BmwDtcDatabase.lookup(
                        d.code,
                        defaultEcu: ecu.germanAbbrev,
                        candidateKeys: ecu.candidateEcuKeys,
                        statusByte: d.status,
                      ))
                  .toList();
              report.state = EcuScanState.responding;
            } catch (_) {
              report.state = EcuScanState.noResponse;
              continue;
            }

            // Read Identification DIDs
            try {
              final vinBytes = await client.readDataByIdentifier(0xF190);
              final vinStr = String.fromCharCodes(vinBytes.where((c) => c >= 32 && c <= 126)).trim();
              if (vinStr.isNotEmpty) report.vin = vinStr;
            } catch (_) {
              report.vin = null;
            }

            try {
              final partBytes = await client.readDataByIdentifier(0xF187);
              report.partNumber = partBytes
                  .map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase())
                  .join();
            } catch (_) {
              report.partNumber = null;
            }

            try {
              final hwBytes = await client.readDataByIdentifier(0xF192);
              final printable = String.fromCharCodes(hwBytes.where((c) => c >= 32 && c <= 126)).trim();
              report.hardwareVersion = printable.isNotEmpty
                  ? printable
                  : hwBytes.map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase()).join();
            } catch (_) {
              report.hardwareVersion = null;
            }

            try {
              final swBytes = await client.readDataByIdentifier(0xF189);
              final printable = String.fromCharCodes(swBytes.where((c) => c >= 32 && c <= 126)).trim();
              report.softwareVersion = printable.isNotEmpty
                  ? printable
                  : swBytes.map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase()).join();
            } catch (_) {
              report.softwareVersion = null;
            }

            try {
              final suppBytes = await client.readDataByIdentifier(0xF18A);
              final printable = String.fromCharCodes(suppBytes.where((c) => c >= 32 && c <= 126)).trim();
              report.supplierName = printable.isNotEmpty
                  ? printable
                  : suppBytes.map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase()).join();
            } catch (_) {
              report.supplierName = null;
            }
          } else {
            report.state = EcuScanState.noResponse;
          }
        } catch (_) {
          report.state = EcuScanState.noResponse;
        }
      }

      _progress = (i + 1) / total;
      notifyListeners();
    }

    _isScanning = false;
    _currentStep = _cancelled
        ? 'Scan stopped'
        : 'Scan complete ($totalResponding ECUs responding, $totalFaults fault codes reported. Zero DTCs does not guarantee complete vehicle health.)';

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
