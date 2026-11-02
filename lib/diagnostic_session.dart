import 'dart:async';
import 'package:flutter/foundation.dart';

import 'diagnostics/auto_scan_controller.dart';
import 'diagnostics/adapter_profile.dart';
import 'diagnostics/coding_manager.dart';
import 'diagnostics/elm_session.dart';
import 'diagnostics/protocol_setup.dart';
import 'diagnostics/uds_client.dart';
import 'diagnostics/vehicle_catalog.dart';
import 'purchases/purchase_controller.dart';

/// App-wide view of the active adapter session used by diagnostic screens.
/// The adapter page owns closing the transport; leaving a diagnostic screen
/// never changes the connection lifecycle.
class DiagnosticSession extends ChangeNotifier {
  DiagnosticSession._() {
    _autoScan.addListener(notifyListeners);
  }

  static final DiagnosticSession instance = DiagnosticSession._();

  PurchaseController? _purchases;
  PurchaseController get purchases {
    if (_purchases == null) {
      _purchases = PurchaseController.fromEnvironment();
      _purchases!.addListener(notifyListeners);
    }
    return _purchases!;
  }

  set purchases(PurchaseController value) {
    if (_purchases != null) {
      _purchases!.removeListener(notifyListeners);
    }
    _purchases = value;
    _purchases!.addListener(notifyListeners);
    notifyListeners();
  }

  ElmSession? _elmSession;
  String? _identity;
  String? _voltage;
  UdsClient? _udsClient;
  BmwBikeUdsLink? _activeLink;
  String? _ecuDefinitionKey;
  int _generation = 0;
  bool _operationBusy = false;
  bool get operationBusy => _operationBusy;
  Future<T> runExclusive<T>(Future<T> Function() operation) async {
    if (_operationBusy) throw StateError('Another diagnostic operation is in progress.');
    _operationBusy = true;
    notifyListeners();
    try { return await operation(); }
    finally { _operationBusy = false; notifyListeners(); }
  }

  final List<String> _events = [];

  // Extended parity states
  final VehicleProfile _profile = VehicleProfile();
  final AutoScanController _autoScan = AutoScanController();
  final BmwCodingManager _codingManager = BmwCodingManager();
  bool _liveStreaming = true;

  ElmSession? get elmSession => _elmSession;
  String? get identity => _identity;
  String? get voltage => _voltage;
  UdsClient? get udsClient => _udsClient;
  String? get ecuDefinitionKey => _ecuDefinitionKey;
  set ecuDefinitionKey(String? value) {
    if (_ecuDefinitionKey != value) {
      if (_operationBusy) throw StateError('Wait for the active diagnostic operation before changing ECU.');
      _udsClient = null;
      _activeLink = null;
      _ecuDefinitionKey = value;
      notifyListeners();
    }
  }
  BmwBikeUdsLink? get activeLink => _activeLink;
  int get generation => _generation;
  bool get connected => _elmSession != null;

  VehicleProfile get profile => _profile;
  AutoScanController get autoScan => _autoScan;
  BmwCodingManager get codingManager => _codingManager;
  bool get liveStreaming => _liveStreaming;

  void toggleLiveStreaming() {
    _liveStreaming = !_liveStreaming;
    notifyListeners();
  }

  void clearVehicleProfile() {
    _profile.modelName = null;
    _profile.modelYear = null;
    _profile.vin = null;
    _profile.odometerKm = null;
    _profile.notes = null;
    _profile.isAutoIdentified = false;
    record('Vehicle profile cleared');
  }

  void updateVehicleProfile({String? model, int? year, String? vin, int? odometer, bool? autoIdentified}) {
    if (model != null) _profile.modelName = model;
    if (year != null) _profile.modelYear = year;
    if (vin != null) _profile.vin = vin;
    if (odometer != null) _profile.odometerKm = odometer;
    if (autoIdentified != null) _profile.isAutoIdentified = autoIdentified;
    record('Vehicle profile updated: ${_profile.modelName ?? 'BMW Motorrad'} ${_profile.modelYear ?? ''}');
    notifyListeners();
  }

  /// True when a vehicle protocol link has been configured for this session.
  /// Adapter identity alone does not establish ECU compatibility.
  bool get protocolReady => connected && _udsClient != null;

  List<String> get events => List.unmodifiable(_events);

  void attach(ElmSession session, {String? identity, String? voltage}) {
    _generation++;
    _elmSession = session;
    unawaited(session.failure.then((error) {
      if (!identical(_elmSession, session)) return;
      record('Adapter connection ended: $error');
      detach();
      unawaited(session.close());
    }));
    _udsClient = null;
    _activeLink = null;
    _ecuDefinitionKey = null;
    _identity = identity;
    _voltage = voltage;
    _events
      ..clear()
      ..add('Adapter connected${identity == null ? '' : ': $identity'}');
    if (voltage != null) _events.add('Adapter voltage: $voltage');
    notifyListeners();
  }

  void invalidateVehicleProtocol() {
    _udsClient = null;
    _activeLink = null;
    _ecuDefinitionKey = null;
    notifyListeners();
  }

  void attachUdsClient(UdsClient client, {int? forGeneration, BmwBikeUdsLink? link, String? ecuKey}) {
    if (!connected || (forGeneration != null && forGeneration != _generation)) {
      throw StateError(
          'The adapter connection changed before protocol setup completed.');
    }
    _udsClient = client;
    _activeLink = link;
    _ecuDefinitionKey = ecuKey;
    record('Vehicle protocol configured');
  }

  Future<UdsClient> configureUdsTarget({required String ecuKey, required int address,
      BmwUdsAdapterType? adapterType, Future<void> Function(Duration)? settleDelay}) {
    return runExclusive(() async {
      final session = _elmSession;
      final generation = _generation;
      if (session == null) throw StateError('Connect an adapter first.');
      invalidateVehicleProtocol();
      await initializeAdapter(session, delay: settleDelay ?? Future<void>.delayed);
      final link = BmwBikeUdsLink(session, adapterType: adapterType);
      if (!await link.configure(id: address)) throw StateError('Adapter rejected ECU configuration.');
      if (!identical(_elmSession, session) || generation != _generation) {
        throw StateError('Adapter changed during ECU configuration.');
      }
      final client = UdsClient(link);
      attachUdsClient(client, forGeneration: generation, link: link, ecuKey: ecuKey);
      return client;
    });
  }

  void detach() {
    if (!connected) return;
    _generation++;
    record('Adapter disconnected');
    _elmSession = null;
    _udsClient = null;
    _activeLink = null;
    _ecuDefinitionKey = null;
    _identity = null;
    _voltage = null;
    notifyListeners();
  }

  void record(String event) {
    _events.add(event);
    if (_events.length > 100) _events.removeAt(0);
    notifyListeners();
  }

  Future<String> readAdapterVoltage() async {
    if (_operationBusy) throw StateError('Another diagnostic operation is in progress.');
    final session = _elmSession;
    if (session == null) throw StateError('Connect an adapter first.');
    final generation = _generation;
    final response = await session.command('ATRV');
    _ensureCurrent(generation, session: session);
    if (response.isError || response.lines.isEmpty) {
      record(
          'Adapter voltage read failed: ${response.text.isEmpty ? 'no response' : response.text}');
      throw StateError(response.text.isEmpty
          ? 'Adapter returned no voltage.'
          : response.text);
    }
    _voltage = response.text;
    record('Adapter voltage: ${response.text}');
    notifyListeners();
    return response.text;
  }

  Future<UdsDtcReport> readFaults() async {
    if (_operationBusy) throw StateError('Another diagnostic operation is in progress.');
    final client = _udsClient;
    if (!protocolReady || client == null) {
      throw StateError('Configure the vehicle protocol first.');
    }
    final generation = _generation;
    record('Fault code scan started');
    final report = await client.readDtcByStatusMask(0xff);
    _ensureCurrent(generation, client: client);
    record('Fault code scan returned ${report.dtcs.length} code(s)');
    return report;
  }

  Future<List<int>> readDataIdentifier(int did) async {
    if (_operationBusy) throw StateError('Another diagnostic operation is in progress.');
    final client = _udsClient;
    if (!protocolReady || client == null) {
      throw StateError('Configure the vehicle protocol first.');
    }
    final generation = _generation;
    record(
        'Read vehicle data identifier 0x${did.toRadixString(16).padLeft(4, '0')}');
    final data = await client.readDataByIdentifier(did);
    _ensureCurrent(generation, client: client);
    return data;
  }

  Future<void> clearFaults() async {
    if (_operationBusy) throw StateError('Another diagnostic operation is in progress.');
    final client = _udsClient;
    if (!protocolReady || client == null) {
      throw StateError('Configure the vehicle protocol first.');
    }
    final generation = _generation;
    record('Clear fault codes requested');
    await client.clearDtc();
    _ensureCurrent(generation, client: client);
    record('ECU confirmed fault code clear');
  }

  void _ensureCurrent(int generation,
      {ElmSession? session, UdsClient? client}) {
    if (generation != _generation ||
        (session != null && !identical(session, _elmSession)) ||
        (client != null && !identical(client, _udsClient))) {
      throw StateError(
          'The adapter connection changed before the operation completed.');
    }
  }
}
