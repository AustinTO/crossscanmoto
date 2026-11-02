import 'package:flutter/material.dart';

import 'diagnostic_session.dart';
import 'recovered_actuator_panel.dart';
import 'diagnostics/coding_manager.dart';
import 'diagnostics/ecu_friendly_names.dart';
import 'diagnostics/service_manager.dart';
import 'diagnostics/service_reset_protocol.dart';

const _lime = Color(0xFFBCEB58);
const _panel = Color(0xFF14191B);
const _ink = Color(0xFF0A0D0E);
const _muted = Color(0xFF929B9B);

/// Comprehensive Service maintenance, Coding and Backup workshop interface.
class ServiceCodingPage extends StatefulWidget {
  const ServiceCodingPage({super.key});

  @override
  State<ServiceCodingPage> createState() => _ServiceCodingPageState();
}

class _ServiceCodingPageState extends State<ServiceCodingPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  bool _busy = false;
  bool _serviceCancelRequested = false;
  bool _disposed = false;
  int _serviceOperationGeneration = 0;
  String? _notice;
  String? _serviceEcuKey;
  bool _showAdvancedEcuSelection = false;
  ServiceFunctionItem? _pendingServiceItem;
  ServiceFunctionType _serviceAction = ServiceFunctionType.setNextServiceDate;
  DateTime _vehicleDateTime = DateTime.now();
  DateTime _nextServiceDate = DateTime.now().add(const Duration(days: 365));
  final _serviceMileageController = TextEditingController(text: '10000');

  @override
  void initState() {
    super.initState();
    _serviceEcuKey =
        DiagnosticSession.instance.ecuDefinitionKey ??
        BmwServiceManager.supportedEcuKeys.first;
    _tabs = TabController(length: 4, vsync: this);
    DiagnosticSession.instance.addListener(_sessionChanged);
  }

  @override
  void dispose() {
    _disposed = true;
    _serviceCancelRequested = true;
    _serviceOperationGeneration++;
    DiagnosticSession.instance.removeListener(_sessionChanged);
    _tabs.dispose();
    _serviceMileageController.dispose();
    super.dispose();
  }

  void _sessionChanged() {
    if (mounted) {
      final active = DiagnosticSession.instance.ecuDefinitionKey;
      if (active != null &&
          BmwServiceManager.supportedEcuKeys.contains(active)) {
        _serviceEcuKey = active;
      }
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _ink,
      appBar: AppBar(
        backgroundColor: _panel,
        title: const Text(
          'Workshop Functions',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        bottom: TabBar(
          controller: _tabs,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          indicatorColor: _lime,
          labelColor: _lime,
          unselectedLabelColor: Colors.white54,
          labelStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
          tabs: const [
            Tab(text: 'Service Resets'),
            Tab(text: 'Vehicle Coding'),
            Tab(text: 'Local Drafts'),
            Tab(text: 'Actuator Tests'),
          ],
        ),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              if (_notice != null)
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF18261B),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _lime.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: _lime, size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _notice!,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.close,
                          size: 16,
                          color: Colors.white54,
                        ),
                        onPressed: () => setState(() => _notice = null),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: TabBarView(
                  controller: _tabs,
                  children: [
                    _buildServiceTab(),
                    _buildCodingTab(),
                    _buildBackupTab(),
                    _buildActuatorTab(),
                  ],
                ),
              ),
            ],
          ),
          if (_pendingServiceItem != null) _buildServiceConfirmationModal(),
        ],
      ),
    );
  }

  Widget _buildServiceTab() {
    final actions = BmwServiceManager.actions;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _panel,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _ink,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _lime.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: _lime.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.verified,
                            color: _lime,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            'SOURCE-ROUTED SERVICE ECU',
                            style: TextStyle(
                              color: _muted,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.1,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: _lime.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'SELECTED ECU',
                            style: TextStyle(
                              color: _lime,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            BmwEcuHelper.friendlyName(
                              _serviceEcuKey ?? 'cuX_BMSX',
                            ),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 13.5,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        TextButton(
                          onPressed: () => setState(
                            () => _showAdvancedEcuSelection =
                                !_showAdvancedEcuSelection,
                          ),
                          style: TextButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                          ),
                          child: Text(
                            _showAdvancedEcuSelection ? 'Hide' : 'Change',
                            style: const TextStyle(color: _lime, fontSize: 11),
                          ),
                        ),
                      ],
                    ),
                    if (_showAdvancedEcuSelection) ...[
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: _serviceEcuKey,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Override Control Module',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        items: [
                          for (final key in BmwServiceManager.supportedEcuKeys)
                            DropdownMenuItem(
                              value: key,
                              child: Text(BmwEcuHelper.friendlyName(key)),
                            ),
                        ],
                        onChanged: _busy
                            ? null
                            : (value) => setState(() => _serviceEcuKey = value),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<ServiceFunctionType>(
                initialValue: _serviceAction,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Service operation',
                  border: OutlineInputBorder(),
                ),
                items: [
                  for (final item in actions)
                    DropdownMenuItem(value: item.type, child: Text(item.title)),
                ],
                onChanged: _busy
                    ? null
                    : (value) => setState(() => _serviceAction = value!),
              ),
              const SizedBox(height: 12),
              _dateSelector(
                label: 'Bike date and time',
                value: _vehicleDateTime,
                onPressed: () => _chooseServiceDate(vehicleDateTime: true),
              ),
              _dateSelector(
                label: 'Next service date',
                value: _nextServiceDate,
                onPressed: () => _chooseServiceDate(vehicleDateTime: false),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _serviceMileageController,
                enabled: !_busy,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Next service mileage value',
                  helperText: 'Service due mileage (e.g. 10000 km)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _busy || _serviceEcuKey == null
                    ? null
                    : _executeService,
                icon: _busy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.build_circle_outlined, size: 18),
                label: Text(
                  _busy ? 'Writing and verifying…' : 'Execute verified reset',
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: _lime,
                  foregroundColor: _ink,
                  minimumSize: const Size.fromHeight(42),
                ),
              ),
              if (_busy)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: _serviceCancelRequested
                        ? null
                        : _requestServiceCancellation,
                    icon: const Icon(Icons.stop_circle_outlined, size: 18),
                    label: Text(
                      _serviceCancelRequested
                          ? 'Stopping after the current request…'
                          : 'Stop service operation',
                    ),
                  ),
                ),
            ],
          ),
        ),
        for (final item in actions)
          ListTile(
            title: Text(item.title),
            subtitle: Text(
              item.description,
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ),
      ],
    );
  }

  Widget _dateSelector({
    required String label,
    required DateTime value,
    required VoidCallback onPressed,
  }) => Padding(
    padding: const EdgeInsets.only(top: 8),
    child: OutlinedButton(
      onPressed: _busy ? null : onPressed,
      child: Row(
        children: [
          const Icon(Icons.calendar_month_outlined, size: 18),
          const SizedBox(width: 10),
          Expanded(child: Text('$label • ${_dateLabel(value)}')),
        ],
      ),
    ),
  );

  Future<void> _chooseServiceDate({required bool vehicleDateTime}) async {
    final current = vehicleDateTime ? _vehicleDateTime : _nextServiceDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked == null || !mounted) return;
    final withExistingTime = DateTime(
      picked.year,
      picked.month,
      picked.day,
      current.hour,
      current.minute,
      current.second,
    );
    setState(() {
      if (vehicleDateTime) {
        _vehicleDateTime = withExistingTime;
      } else {
        _nextServiceDate = withExistingTime;
      }
    });
  }

  Future<void> _executeService() async {
    final mileage = int.tryParse(_serviceMileageController.text.trim());
    if (mileage == null) {
      setState(
        () => _notice = 'Please enter a valid numeric service mileage value.',
      );
      return;
    }

    final item = BmwServiceManager.actions.firstWhere(
      (candidate) => candidate.type == _serviceAction,
    );
    setState(() => _pendingServiceItem = item);
  }

  Future<void> _confirmAndPerformService() async {
    final operationGeneration = ++_serviceOperationGeneration;
    _serviceCancelRequested = false;
    final item = _pendingServiceItem;
    final key = _serviceEcuKey ?? BmwServiceManager.supportedEcuKeys.first;
    final mileage = int.tryParse(_serviceMileageController.text.trim());
    if (mileage == null || mileage < 0 || mileage > 65535) {
      setState(
        () => _notice = 'Enter a service mileage value from 0 to 65535.',
      );
      return;
    }
    setState(() => _pendingServiceItem = null);

    if (item == null) return;

    final shared = DiagnosticSession.instance;
    var link = shared.activeLink;
    if ((link == null || shared.ecuDefinitionKey != key) && shared.connected) {
      link = null;
      setState(() {
        _busy = true;
        _notice =
            'Establishing diagnostic link to ${BmwEcuHelper.friendlyName(key)}…';
      });
      try {
        final route = BmwServiceResetCatalog.routeForEcuKey(key);
        if (route == null) {
          throw UnsupportedError('No source-backed service route for $key.');
        }
        await shared.configureUdsTarget(
          ecuKey: key,
          address: route.address,
        );
        link = shared.activeLink;
      } catch (error) {
        if (mounted) setState(() => _notice = 'Connection failed: $error');
      } finally {
        if (mounted) setState(() => _busy = false);
      }
    }

    if (!mounted ||
        _disposed ||
        _serviceCancelRequested ||
        operationGeneration != _serviceOperationGeneration) {
      if (mounted) {
        setState(() {
          _busy = false;
          _notice = 'Service operation cancelled before any write was sent.';
        });
      }
      return;
    }

    if (link == null) {
      if (mounted) {
        setState(
          () => _notice =
              'Connect your OBD adapter in the Adapter tab to execute live service operations.',
        );
      }
      return;
    }

    final targetGeneration = shared.generation;
    bool shouldAbort() =>
        _serviceCancelRequested ||
        _disposed ||
        operationGeneration != _serviceOperationGeneration ||
        shared.generation != targetGeneration ||
        !identical(shared.activeLink, link) ||
        shared.ecuDefinitionKey != key;

    if (!mounted) return;
    setState(() {
      _busy = true;
      _notice = null;
    });
    final result = await DiagnosticSession.instance
        .runExclusive(
          () => BmwServiceManager.execute(
            item: item,
            link: link!,
            ecuKey: key,
            vehicleDateTime: _vehicleDateTime,
            nextServiceDate: _nextServiceDate,
            nextServiceMileage: mileage,
            shouldAbort: shouldAbort,
          ),
        )
        .catchError(
          (Object error) =>
              ServiceExecutionResult(success: false, message: error.toString()),
        );
    if (!mounted ||
        _disposed ||
        operationGeneration != _serviceOperationGeneration)
      return;
    setState(() {
      _busy = false;
      _notice = result.message;
      if (result.success && result.newServiceDate != null) {
        _nextServiceDate = result.newServiceDate!;
      }
      if (result.success && result.newServiceMileageKm != null) {
        _serviceMileageController.text = result.newServiceMileageKm.toString();
      }
    });
  }

  void _requestServiceCancellation() {
    if (!_busy || _serviceCancelRequested) return;
    setState(() {
      _serviceCancelRequested = true;
      _notice = 'Stopping after the current diagnostic request completes…';
    });
  }

  Widget _buildServiceConfirmationModal() {
    final item = _pendingServiceItem;
    if (item == null) return const SizedBox.shrink();
    final key = _serviceEcuKey ?? BmwServiceManager.supportedEcuKeys.first;
    return Container(
      color: Colors.black.withValues(alpha: 0.75),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      alignment: Alignment.center,
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 420),
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: _panel,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _lime.withValues(alpha: 0.3)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _lime.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.build_circle_outlined,
                      color: _lime,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Confirm Service Reset',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Apply "${item.title}" to ${BmwEcuHelper.friendlyName(key)}?\n\nThe new service interval and vehicle date will be calibrated directly on the motorcycle.',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 13.5,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white70,
                        side: const BorderSide(color: Colors.white24),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () =>
                          setState(() => _pendingServiceItem = null),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: _lime,
                        foregroundColor: _ink,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: _confirmAndPerformService,
                      child: const Text(
                        'Calibrate & Verify',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _dateLabel(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}.${value.month.toString().padLeft(2, '0')}.${value.year.toString().padLeft(4, '0')}';

  Widget _buildCodingTab() {
    final manager = DiagnosticSession.instance.codingManager;
    final values = manager.currentValues;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: const Color(0xFF192224),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _lime.withValues(alpha: 0.2)),
          ),
          child: const Row(
            children: [
              Icon(Icons.shield_outlined, color: _lime, size: 24),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'These presets and snapshots are local coding drafts. ECU coding requires a verified definition for the selected control unit.',
                  style: TextStyle(fontSize: 12, color: Colors.white70),
                ),
              ),
            ],
          ),
        ),

        // TFT Startup Animation
        _buildCodingDropdown<String>(
          title: BmwCodingManager.startupAnimationOption.title,
          description: BmwCodingManager.startupAnimationOption.description,
          ecu: BmwCodingManager.startupAnimationOption.ecuAcronym,
          value: values['startup_animation'] as String? ?? 'M Motorsport',
          options: BmwCodingManager.startupAnimationOption.values,
          onChanged: (val) {
            setState(() => manager.setValue('startup_animation', val));
            _showCodingSuccess('Startup animation set to $val');
          },
        ),

        // Clock Format
        _buildCodingDropdown<String>(
          title: BmwCodingManager.clockFormatOption.title,
          description: BmwCodingManager.clockFormatOption.description,
          ecu: BmwCodingManager.clockFormatOption.ecuAcronym,
          value: values['clock_format'] as String? ?? '24h',
          options: BmwCodingManager.clockFormatOption.values,
          onChanged: (val) {
            setState(() => manager.setValue('clock_format', val));
            _showCodingSuccess('Clock format set to $val');
          },
        ),

        // Temp Unit
        _buildCodingDropdown<String>(
          title: BmwCodingManager.tempUnitOption.title,
          description: BmwCodingManager.tempUnitOption.description,
          ecu: BmwCodingManager.tempUnitOption.ecuAcronym,
          value: values['temp_unit'] as String? ?? '°C',
          options: BmwCodingManager.tempUnitOption.values,
          onChanged: (val) {
            setState(() => manager.setValue('temp_unit', val));
            _showCodingSuccess('Temperature unit set to $val');
          },
        ),

        // Pressure Unit
        _buildCodingDropdown<String>(
          title: BmwCodingManager.pressureUnitOption.title,
          description: BmwCodingManager.pressureUnitOption.description,
          ecu: BmwCodingManager.pressureUnitOption.ecuAcronym,
          value: values['pressure_unit'] as String? ?? 'bar',
          options: BmwCodingManager.pressureUnitOption.values,
          onChanged: (val) {
            setState(() => manager.setValue('pressure_unit', val));
            _showCodingSuccess('Tire pressure unit set to $val');
          },
        ),

        // LED Indicators Retrofit
        _buildCodingSwitch(
          title: BmwCodingManager.ledIndicatorsOption.title,
          description: BmwCodingManager.ledIndicatorsOption.description,
          ecu: BmwCodingManager.ledIndicatorsOption.ecuAcronym,
          value: values['led_indicators'] as bool? ?? true,
          onChanged: (val) {
            setState(() => manager.setValue('led_indicators', val));
            _showCodingSuccess(
              'LED Turn Signals retrofit ${val ? "enabled" : "disabled"}',
            );
          },
        ),

        // Daytime Running Lights
        _buildCodingSwitch(
          title: BmwCodingManager.drlOption.title,
          description: BmwCodingManager.drlOption.description,
          ecu: BmwCodingManager.drlOption.ecuAcronym,
          value: values['daytime_running_lights'] as bool? ?? true,
          onChanged: (val) {
            setState(() => manager.setValue('daytime_running_lights', val));
            _showCodingSuccess(
              'Daytime Running Lights ${val ? "enabled" : "disabled"}',
            );
          },
        ),

        // Auxiliary Fog Lights
        _buildCodingSwitch(
          title: BmwCodingManager.auxFogLightsOption.title,
          description: BmwCodingManager.auxFogLightsOption.description,
          ecu: BmwCodingManager.auxFogLightsOption.ecuAcronym,
          value: values['auxiliary_fog_lights'] as bool? ?? false,
          onChanged: (val) {
            setState(() => manager.setValue('auxiliary_fog_lights', val));
            _showCodingSuccess(
              'Auxiliary Fog Lights ${val ? "enabled" : "disabled"}',
            );
          },
        ),
      ],
    );
  }

  Widget _buildBackupTab() {
    final manager = DiagnosticSession.instance.codingManager;
    final snapshots = manager.snapshots;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'LOCAL CONFIGURATION DRAFTS',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
                color: Colors.white60,
              ),
            ),
            FilledButton.icon(
              onPressed: () {
                final snap = manager.createSnapshot(
                  model:
                      DiagnosticSession.instance.profile.modelName ??
                      'Unidentified motorcycle',
                  vin: DiagnosticSession.instance.profile.vin ?? 'UNKNOWN',
                );
                setState(
                  () => _notice =
                      'Snapshot ${snap.id} saved in memory; no ECU data was read.',
                );
              },
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Save Local Draft'),
              style: FilledButton.styleFrom(
                backgroundColor: _lime,
                foregroundColor: _ink,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        if (snapshots.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: _panel,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
            ),
            child: const Center(
              child: Text(
                'No backup snapshots yet. Tap "Save Local Draft" to save a backup of all vehicle module codings before making modifications.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white54, fontSize: 13),
              ),
            ),
          )
        else
          for (final snap in snapshots)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _panel,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        snap.id,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _lime,
                          fontFamily: 'monospace',
                        ),
                      ),
                      Text(
                        snap.formattedDate,
                        style: const TextStyle(
                          color: Colors.white38,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${snap.vehicleModel} • VIN: ${snap.vin}',
                    style: const TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () {
                      manager.restoreSnapshot(snap.id);
                      setState(
                        () =>
                            _notice = 'Restored configuration from ${snap.id}',
                      );
                    },
                    icon: const Icon(Icons.restore, size: 16),
                    label: const Text('Load Local Draft'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _lime,
                      side: const BorderSide(color: _lime),
                      minimumSize: const Size.fromHeight(36),
                    ),
                  ),
                ],
              ),
            ),
      ],
    );
  }

  Widget _buildActuatorTab() => const RecoveredActuatorPanel();

  Widget _buildCodingDropdown<T>({
    required String title,
    required String description,
    required String ecu,
    required T value,
    required List<T> options,
    required ValueChanged<T> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _panel,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _lime.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  ecu,
                  style: const TextStyle(
                    color: _lime,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            description,
            style: const TextStyle(color: Colors.white54, fontSize: 11),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<T>(
            initialValue: value,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            items: options
                .map(
                  (opt) =>
                      DropdownMenuItem(value: opt, child: Text(opt.toString())),
                )
                .toList(),
            onChanged: (newVal) {
              if (newVal != null) onChanged(newVal);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCodingSwitch({
    required String title,
    required String description,
    required String ecu,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _panel,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: _lime.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        ecu,
                        style: const TextStyle(
                          color: _lime,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: const TextStyle(color: Colors.white54, fontSize: 11),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            activeTrackColor: _lime.withValues(alpha: 0.5),
            activeThumbColor: _lime,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  void _showCodingSuccess(String message) {
    setState(() => _notice = message);
  }
}
