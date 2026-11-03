import 'package:flutter/material.dart';

import 'diagnostic_session.dart';
import 'diagnostics/dtc_database.dart';
import 'diagnostics/elm_session.dart';
import 'diagnostics/kwp_client.dart';
import 'diagnostics/kwp_response.dart';
import 'diagnostics/service_manager.dart';

/// Expert diagnostics for a known legacy BMW motorcycle KWP ECU address.
/// The adapter connection remains owned by the app-wide diagnostic session.
class LegacyKwpPage extends StatefulWidget {
  const LegacyKwpPage({super.key, this.originalEcuKey});

  /// Optional original catalog key, for example `cuMRABS`.
  final String? originalEcuKey;

  @override
  State<LegacyKwpPage> createState() => _LegacyKwpPageState();
}

class _LegacyKwpPageState extends State<LegacyKwpPage> {
  final _address = TextEditingController();
  final _ecuKey = TextEditingController();
  final _parameterId = TextEditingController();
  final _serviceMileage = TextEditingController(text: '10000');
  String _serviceClusterKey = 'MRKOMBI';
  DateTime _serviceDate = DateTime.now().add(const Duration(days: 365));
  final _shared = DiagnosticSession.instance;

  ElmSession? _observedSession;
  int _observedGeneration = 0;
  bool _observedUdsReady = false;
  bool _observedOperationBusy = false;
  bool _expectedKwpInvalidation = false;
  int _operationToken = 0;

  BmwBikeKwpLink? _link;
  KwpClient? _client;
  int? _configuredAddress;
  int? _configuredGeneration;
  bool _busy = false;
  String? _status;
  List<int>? _identification;
  String? _vin;
  KwpDtcReport? _dtcReport;
  List<int>? _parameterBytes;

  @override
  void initState() {
    super.initState();
    _ecuKey.text = widget.originalEcuKey ?? '';
    _observedSession = _shared.elmSession;
    _observedGeneration = _shared.generation;
    _observedUdsReady = _shared.protocolReady;
    _observedOperationBusy = _shared.operationBusy;
    _shared.addListener(_onSharedSessionChanged);
  }

  @override
  void dispose() {
    _operationToken++;
    _shared.removeListener(_onSharedSessionChanged);
    // KWP configuration invalidates UDS readiness. Never close the shared ELM
    // session here; its owning adapter screen controls the connection lifetime.
    if (!_shared.operationBusy && !_shared.protocolReady) {
      _shared.invalidateVehicleProtocol();
    }
    _address.dispose();
    _ecuKey.dispose();
    _parameterId.dispose();
    _serviceMileage.dispose();
    super.dispose();
  }

  void _onSharedSessionChanged() {
    final session = _shared.elmSession;
    final generation = _shared.generation;
    final udsReady = _shared.protocolReady;
    final operationBusy = _shared.operationBusy;
    final udsReadyChanged = udsReady != _observedUdsReady;
    if (identical(session, _observedSession) &&
        generation == _observedGeneration &&
        udsReady == _observedUdsReady &&
        operationBusy == _observedOperationBusy) {
      return;
    }

    final adapterChanged =
        !identical(session, _observedSession) ||
        generation != _observedGeneration;
    final expectedInvalidation =
        _expectedKwpInvalidation &&
        !adapterChanged &&
        _observedUdsReady &&
        !udsReady;
    _observedSession = session;
    _observedGeneration = generation;
    _observedUdsReady = udsReady;
    _observedOperationBusy = operationBusy;

    // runExclusive notifies on lock transitions. The UDS-to-KWP invalidation
    // is intentional; a session/generation change still cancels the operation.
    if (!adapterChanged && (expectedInvalidation || !udsReadyChanged)) {
      if (mounted) setState(() {});
      return;
    }

    _operationToken++;
    _link = null;
    _client = null;
    _configuredAddress = null;
    _configuredGeneration = null;
    _busy = false;
    _identification = null;
    _dtcReport = null;
    _parameterBytes = null;

    if (!mounted) return;
    setState(() {
      _status = !_shared.connected
          ? 'Adapter disconnected. Reconnect and configure KWP.'
          : adapterChanged
          ? 'Adapter changed. Configure KWP again before continuing.'
          : udsReady
          ? 'A vehicle protocol changed. Configure KWP again before continuing.'
          : 'Adapter or protocol changed. Configure KWP again before continuing.';
    });
  }

  int? get _parsedAddress => _parseHex(_address.text, max: 0xff);
  int? get _parsedParameterId => _parseHex(_parameterId.text, max: 0xffff);

  static int? _parseHex(String value, {required int max}) {
    final text = value.trim();
    if (text.isEmpty || !RegExp(r'^[0-9a-fA-F]+$').hasMatch(text)) return null;
    final parsed = int.tryParse(text, radix: 16);
    if (parsed == null || parsed > max) return null;
    return parsed;
  }

  void _onAddressChanged(String value) {
    final nextAddress = _parseHex(value, max: 0xff);
    if (_configuredAddress != null && nextAddress != _configuredAddress) {
      _operationToken++;
      setState(() {
        _link = null;
        _client = null;
        _configuredAddress = null;
        _configuredGeneration = null;
        _busy = false;
        _identification = null;
        _dtcReport = null;
        _parameterBytes = null;
        _status = 'ECU address changed. Configure KWP again.';
      });
      return;
    }
    setState(() {});
  }

  bool _isCurrent(int token, int generation, ElmSession session) =>
      mounted &&
      token == _operationToken &&
      generation == _shared.generation &&
      identical(session, _shared.elmSession) &&
      !_shared.protocolReady;

  Future<void> _configure() async {
    if (_busy) return;
    if (_shared.operationBusy) {
      setState(
        () => _status = 'Wait for the active diagnostic operation to finish.',
      );
      return;
    }
    final address = _parsedAddress;
    if (address == null) {
      setState(() => _status = 'Enter the ECU address as 00–FF hexadecimal.');
      return;
    }
    final session = _shared.elmSession;
    if (session == null) {
      setState(() => _status = 'Connect an adapter before configuring KWP.');
      return;
    }

    final generation = _shared.generation;
    final token = ++_operationToken;
    final link = BmwBikeKwpLink(session);
    setState(() {
      _busy = true;
      _link = null;
      _client = null;
      _configuredAddress = null;
      _configuredGeneration = null;
      _identification = null;
      _dtcReport = null;
      _parameterBytes = null;
      _status = 'Configuring legacy KWP for ECU ${_hex(address, 2)}…';
    });

    try {
      _expectedKwpInvalidation = true;
      final configured = await _shared.runExclusive(() async {
        // Invalidate UDS readiness under the command lock and before issuing
        // KWP-specific AT setup commands.
        _shared.invalidateVehicleProtocol();
        return link.configure(ecuAddress: address);
      });
      if (!_isCurrent(token, generation, session)) return;
      if (!configured) throw StateError('Adapter rejected BMW KWP setup.');

      setState(() {
        _link = link;
        _client = KwpClient(link);
        _configuredAddress = address;
        _configuredGeneration = generation;
        _status = 'KWP adapter setup is ready. ECU response not yet verified.';
      });
      _shared.record('BMW motorcycle KWP selected for ECU ${_hex(address, 2)}');
    } catch (error) {
      if (_isCurrent(token, generation, session)) {
        setState(() => _status = error.toString());
      }
    } finally {
      _expectedKwpInvalidation = false;
      if (_isCurrent(token, generation, session)) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _run<T>(
    String label,
    Future<T> Function(
      KwpClient client,
      BmwBikeKwpLink link,
      bool Function() isCurrent,
      void Function(String status) updateStatus,
    )
    operation,
    void Function(T result) onSuccess,
  ) async {
    if (_busy) return;
    final client = _client;
    final link = _link;
    final session = _shared.elmSession;
    final generation = _shared.generation;
    if (client == null ||
        link == null ||
        session == null ||
        _configuredGeneration != generation ||
        _shared.protocolReady) {
      setState(() => _status = 'Configure KWP for a known ECU address first.');
      return;
    }
    if (_shared.operationBusy) {
      setState(
        () => _status = 'Wait for the active diagnostic operation to finish.',
      );
      return;
    }

    final token = ++_operationToken;
    bool isCurrent() =>
        _isCurrent(token, generation, session) &&
        identical(link, _link) &&
        identical(client, _client);
    void updateStatus(String status) {
      if (isCurrent()) setState(() => _status = status);
    }

    setState(() {
      _busy = true;
      _status = label;
    });
    try {
      final result = await _shared.runExclusive(
        () => operation(client, link, isCurrent, updateStatus),
      );
      if (!isCurrent()) return;
      setState(() {
        onSuccess(result);
      });
    } catch (error) {
      if (isCurrent()) setState(() => _status = error.toString());
    } finally {
      if (isCurrent()) setState(() => _busy = false);
    }
  }

  Future<void> _identify() async {
    setState(() => _identification = null);
    await _run<List<int>?>(
      'Probing ECU identification…',
      (_, link, __, ___) => link.probeAndIdentify(),
      (bytes) {
        _identification = bytes;
        _status = bytes == null || bytes.isEmpty
            ? 'The ECU did not return an identification response.'
            : 'ECU responded to the KWP identification probe.';
      },
    );
  }

  Future<void> _readVin() async {
    setState(() => _vin = null);
    await _run<List<int>>(
      'Reading VIN via KWP Service 0x1A 0x90…',
      (client, _, __, ___) => client.readIdentification(0x90),
      (bytes) {
        final decoded = String.fromCharCodes(bytes.where((c) => c >= 32 && c <= 126)).trim();
        _vin = decoded.isNotEmpty ? decoded : null;
        _status = _vin != null
            ? 'VIN read successfully: $_vin'
            : 'The ECU did not return a valid VIN string.';
      },
    );
  }

  Future<void> _readDtcs() async {
    setState(() => _dtcReport = null);
    await _run<KwpDtcReport>(
      'Reading legacy KWP trouble codes…',
      (client, _, __, ___) => client.readDtc(),
      (report) {
        _dtcReport = report;
        _status = 'Readback returned ${report.dtcs.length} DTC(s).';
      },
    );
  }

  Future<void> _clearDtcs() async {
    if (_busy || _shared.operationBusy || _client == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear legacy KWP fault codes?'),
        content: const Text(
          'This sends a KWP diagnostic fault clear request to the selected module. '
          'The page will read the DTC list again after the ECU confirms.',
        ),
        actions: [
          TextButton(
            key: const ValueKey('kwp-clear-cancel'),
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            key: const ValueKey('kwp-clear-confirm'),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear codes'),
          ),
        ],
      ),
    );
    if (!mounted || confirmed != true) return;

    setState(() => _dtcReport = null);
    await _run<KwpDtcReport>(
      'Sending the confirmed KWP clear request…',
      (client, _, isCurrent, updateStatus) async {
        await client.clearDtc();
        if (!isCurrent()) throw StateError('Adapter connection changed.');
        updateStatus('ECU acknowledged clear. Reading DTCs again…');
        return client.readDtc();
      },
      (report) {
        _dtcReport = report;
        _status =
            'ECU acknowledged clear; ${report.dtcs.length} DTC(s) returned on readback.';
      },
    );
  }

  Future<void> _readParameter() async {
    final parameterId = _parsedParameterId;
    if (parameterId == null) {
      setState(
        () => _status = 'Enter a parameter ID as 0000–FFFF hexadecimal.',
      );
      return;
    }
    setState(() => _parameterBytes = null);
    await _run<List<int>>(
      'Reading KWP parameter 0x${_hex(parameterId, 4)}…',
      (client, _, __, ___) => client.readParameter(parameterId),
      (bytes) {
        _parameterBytes = bytes;
        _status = 'Raw KWP parameter response received.';
      },
    );
  }

  Future<void> _executeLegacyServiceReset(ServiceFunctionType type) async {
    final link = _link;
    if (link == null) return;
    final effectiveEcuKey = _ecuKey.text.trim().isNotEmpty &&
            BmwServiceManager.supportedKwpEcuKeys.contains(_ecuKey.text.trim())
        ? _ecuKey.text.trim()
        : _serviceClusterKey;

    final mileage = int.tryParse(_serviceMileage.text.trim());
    if ((type == ServiceFunctionType.setNextServiceMileage ||
            type == ServiceFunctionType.setAllServiceData) &&
        (mileage == null || mileage < 0 || mileage > 65535)) {
      setState(() => _status = 'Enter a valid service mileage between 0 and 65535 km.');
      return;
    }

    final item = BmwServiceManager.actions.firstWhere((a) => a.type == type);
    await _run<ServiceExecutionResult>(
      'Sending KWP Service 0x3B write (${item.title})…',
      (_, kwpLink, __, ___) => BmwServiceManager.executeKwp(
        item: item,
        link: kwpLink,
        ecuKey: effectiveEcuKey,
        vehicleDateTime: DateTime.now(),
        nextServiceDate: _serviceDate,
        nextServiceMileage: mileage,
      ),
      (res) {
        _status = res.message;
      },
    );
  }

  static String _hex(int value, int width) =>
      value.toRadixString(16).padLeft(width, '0').toUpperCase();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final operationLocked = _busy || _shared.operationBusy;
    return Scaffold(
      appBar: AppBar(title: const Text('Legacy BMW KWP')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            Text(
              'Known ECU access',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            const Text(
              'Configure one documented ECU address. This page does not scan '
              'or guess addresses.',
            ),
            const SizedBox(height: 18),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _shared.connected
                              ? Icons.bluetooth_connected
                              : Icons.bluetooth_disabled,
                          color: _shared.connected
                              ? colors.primary
                              : colors.onSurfaceVariant,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _shared.connected
                                ? 'Adapter connected${_shared.identity == null ? '' : ' · ${_shared.identity}'}'
                                : 'No adapter connected',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      key: const ValueKey('kwp-ecu-address'),
                      controller: _address,
                      enabled: !operationLocked,
                      maxLength: 2,
                      textCapitalization: TextCapitalization.characters,
                      decoration: const InputDecoration(
                        labelText: 'ECU address (hex)',
                        helperText: 'Enter the known address, 00–FF.',
                      ),
                      onChanged: _onAddressChanged,
                    ),
                    const SizedBox(height: 8),
                    FilledButton(
                      key: const ValueKey('kwp-configure'),
                      onPressed: operationLocked || !_shared.connected
                          ? null
                          : _configure,
                      child: Text(_busy ? 'Working…' : 'Configure KWP'),
                    ),
                    if (_configuredAddress != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Configured for ECU ${_hex(_configuredAddress!, 2)}',
                        style: TextStyle(color: colors.primary),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            if (_status != null) ...[
              const SizedBox(height: 12),
              Semantics(liveRegion: true, child: Text(_status!)),
            ],
            if (_client != null) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Identification and trouble codes',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          OutlinedButton.icon(
                            key: const ValueKey('kwp-identify'),
                            onPressed: operationLocked ? null : _identify,
                            icon: const Icon(Icons.search),
                            label: const Text('Identify ECU'),
                          ),
                          OutlinedButton.icon(
                            key: const ValueKey('kwp-read-vin'),
                            onPressed: operationLocked ? null : _readVin,
                            icon: const Icon(Icons.badge_outlined),
                            label: const Text('Read VIN'),
                          ),
                          OutlinedButton.icon(
                            key: const ValueKey('kwp-read-dtcs'),
                            onPressed: operationLocked ? null : _readDtcs,
                            icon: const Icon(Icons.list_alt),
                            label: const Text('Read DTCs'),
                          ),
                          OutlinedButton.icon(
                            key: const ValueKey('kwp-clear-dtcs'),
                            onPressed: operationLocked ? null : _clearDtcs,
                            icon: const Icon(Icons.delete_outline),
                            label: const Text('Clear DTCs'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        key: const ValueKey('kwp-original-ecu-key'),
                        controller: _ecuKey,
                        enabled: !operationLocked,
                        decoration: const InputDecoration(
                          labelText: 'Original ECU key (optional)',
                          helperText:
                              'Used only to match ECU-specific DTC text, e.g. cuMRABS.',
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                      if (_vin != null) ...[
                        const SizedBox(height: 12),
                        _DataPanel(
                          title: 'Vehicle Identification Number (VIN)',
                          value: _vin!,
                        ),
                      ],
                      if (_identification != null) ...[
                        const SizedBox(height: 12),
                        _DataPanel(
                          title: 'Raw identification response',
                          value: _hexBytes(_identification!),
                        ),
                      ],
                      if (_dtcReport != null) ...[
                        const SizedBox(height: 12),
                        _buildDtcResults(context, _dtcReport!),
                      ],
                    ],
                  ),
                ),
              ),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Live parameter',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        key: const ValueKey('kwp-parameter-id'),
                        controller: _parameterId,
                        enabled: !operationLocked,
                        maxLength: 4,
                        textCapitalization: TextCapitalization.characters,
                        decoration: const InputDecoration(
                          labelText: 'Parameter ID (hex)',
                          helperText: 'Enter a catalogued ID, 0000–FFFF.',
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                      FilledButton.tonalIcon(
                        key: const ValueKey('kwp-read-parameter'),
                        onPressed: operationLocked || _parsedParameterId == null
                            ? null
                            : _readParameter,
                        icon: const Icon(Icons.download_outlined),
                        label: const Text('Read parameter'),
                      ),
                      if (_parameterBytes != null) ...[
                        const SizedBox(height: 12),
                        _DataPanel(
                          title: 'Raw parameter bytes',
                          value: _hexBytes(_parameterBytes!),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              _buildServiceResetCard(context),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildServiceResetCard(BuildContext context) {
    final operationLocked = _busy || _shared.operationBusy;
    final colors = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.build_circle_outlined, color: colors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Legacy Cluster Service Reset (Service 0x3B)',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Sets vehicle clock, service due date, and service mileage via KWP Service 0x3B '
              '(MotoScan qr.C / rr.C parity). Supported on K25, K46, and K18 clusters.',
              style: TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              key: const ValueKey('kwp-service-cluster-key'),
              initialValue: _serviceClusterKey,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Cluster model (MotoScan handler route)',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              items: const [
                DropdownMenuItem(value: 'MRKOMBI', child: Text('MRKOMBI · R1200GS / K25 (rr.C selector 1)')),
                DropdownMenuItem(value: 'MRKOMB46', child: Text('MRKOMB46 · S1000RR / K46 (rr.C selector 0)')),
                DropdownMenuItem(value: 'MRKOMB18', child: Text('MRKOMB18 · C600 / K18 (qr.C)')),
                DropdownMenuItem(value: 'cuMRKOMBI', child: Text('cuMRKOMBI · Catalog alias')),
                DropdownMenuItem(value: 'cuMRKOMB46', child: Text('cuMRKOMB46 · Catalog alias')),
                DropdownMenuItem(value: 'cuMRKOMB18', child: Text('cuMRKOMB18 · Catalog alias')),
                DropdownMenuItem(value: 'cuMRKOMB', child: Text('cuMRKOMB · Generic KWP Kombi')),
              ],
              onChanged: operationLocked
                  ? null
                  : (value) {
                      if (value != null) setState(() => _serviceClusterKey = value);
                    },
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: operationLocked
                  ? null
                  : () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _serviceDate,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) setState(() => _serviceDate = picked);
                    },
              icon: const Icon(Icons.calendar_month, size: 16),
              label: Text(
                'Next Service Date: ${_serviceDate.year}-${_serviceDate.month.toString().padLeft(2, '0')}-${_serviceDate.day.toString().padLeft(2, '0')}',
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              key: const ValueKey('kwp-service-mileage'),
              controller: _serviceMileage,
              enabled: !operationLocked,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Next Service Mileage (km)',
                helperText: 'Enter mileage between 0 and 65535 km.',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 14),
            FilledButton.icon(
              key: const ValueKey('kwp-service-reset-all'),
              onPressed: operationLocked
                  ? null
                  : () => _executeLegacyServiceReset(ServiceFunctionType.setAllServiceData),
              icon: const Icon(Icons.done_all, size: 16),
              label: const Text('Update All Service Data (3B 10 / 11 / 12)'),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  key: const ValueKey('kwp-service-set-date'),
                  onPressed: operationLocked
                      ? null
                      : () => _executeLegacyServiceReset(ServiceFunctionType.setNextServiceDate),
                  icon: const Icon(Icons.event, size: 16),
                  label: const Text('Set Date Only (3B 11)'),
                ),
                OutlinedButton.icon(
                  key: const ValueKey('kwp-service-set-mileage'),
                  onPressed: operationLocked
                      ? null
                      : () => _executeLegacyServiceReset(ServiceFunctionType.setNextServiceMileage),
                  icon: const Icon(Icons.speed, size: 16),
                  label: const Text('Set Mileage Only (3B 12)'),
                ),
                OutlinedButton.icon(
                  key: const ValueKey('kwp-service-set-time'),
                  onPressed: operationLocked
                      ? null
                      : () => _executeLegacyServiceReset(ServiceFunctionType.setVehicleDateTime),
                  icon: const Icon(Icons.access_time, size: 16),
                  label: const Text('Sync Clock (3B 10)'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDtcResults(BuildContext context, KwpDtcReport report) {
    if (report.dtcs.isEmpty) {
      return const _DataPanel(
        title: 'KWP DTC readback',
        value: 'No DTCs returned.',
      );
    }
    final ecuKey = _ecuKey.text.trim();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'KWP DTC readback · ${report.dtcs.length}',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        for (final dtc in report.dtcs)
          Builder(
            builder: (context) {
              final record = BmwDtcDatabase.lookup(
                dtc.code,
                defaultEcu: 'BMW KWP ECU',
                ecuKey: ecuKey.isEmpty ? null : ecuKey,
                statusByte: dtc.opaqueRecordByte,
                isUds: false,
              );
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: ListTile(
                  leading: const Icon(Icons.warning_amber_rounded),
                  title: Text('${record.hexCode} · ${record.title}'),
                  subtitle: Text(
                    record.description == record.title
                        ? 'Record byte 3: 0x${_hex(dtc.opaqueRecordByte, 2)} (uninterpreted)'
                        : '${record.description}\nRecord byte 3: 0x${_hex(dtc.opaqueRecordByte, 2)} (uninterpreted)',
                  ),
                  isThreeLine: true,
                ),
              );
            },
          ),
      ],
    );
  }

  static String _hexBytes(List<int> bytes) => bytes.isEmpty
      ? '(empty response)'
      : bytes.map((byte) => _hex(byte, 2)).join(' ');
}

class _DataPanel extends StatelessWidget {
  const _DataPanel({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(14),
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 6),
        SelectableText(value),
      ],
    ),
  );
}
