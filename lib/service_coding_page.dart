import 'package:flutter/material.dart';

import 'diagnostic_session.dart';
import 'bmw_capability_catalog.dart';
import 'recovered_actuator_panel.dart';
import 'recovered_coding_panel.dart';
import 'diagnostics/ecu_friendly_names.dart';
import 'diagnostics/kwp_client.dart';
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
        BmwServiceManager.allSupportedEcuKeys.first;
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
          BmwServiceManager.allSupportedEcuKeys.contains(active)) {
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
            Tab(text: 'Actuator Tests'),
            Tab(text: 'ECU Coding & Backup'),
            Tab(text: 'Capability Catalog'),
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
                    _buildActuatorTab(),
                    const RecoveredCodingPanel(),
                    const BmwCapabilityCatalogBrowser(),
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
                          for (final key in BmwServiceManager.allSupportedEcuKeys)
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
    final key = _serviceEcuKey ?? BmwServiceManager.allSupportedEcuKeys.first;
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
    final isKwp = BmwServiceManager.supportedKwpEcuKeys.contains(key);
    var udsLink = shared.activeLink;
    BmwBikeKwpLink? kwpLink;

    if (isKwp) {
      final session = shared.elmSession;
      if (session != null) {
        kwpLink = BmwBikeKwpLink(session);
        setState(() {
          _busy = true;
          _notice =
              'Configuring legacy KWP link for ${BmwEcuHelper.friendlyName(key)}…';
        });
        try {
          final configured = await shared.runExclusive(() async {
            shared.invalidateVehicleProtocol();
            return kwpLink!.configure(ecuAddress: 0x60);
          });
          if (!configured) {
            throw StateError('Adapter rejected legacy KWP setup for KOMBI (0x60).');
          }
        } catch (error) {
          if (mounted) setState(() => _notice = 'Connection failed: $error');
          kwpLink = null;
        } finally {
          if (mounted) setState(() => _busy = false);
        }
      }
    } else if ((udsLink == null || shared.ecuDefinitionKey != key) && shared.connected) {
      udsLink = null;
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
        udsLink = shared.activeLink;
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

    if ((!isKwp && udsLink == null) || (isKwp && kwpLink == null)) {
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
        (!isKwp && !identical(shared.activeLink, udsLink)) ||
        (!isKwp && shared.ecuDefinitionKey != key);

    if (!mounted) return;
    setState(() {
      _busy = true;
      _notice = null;
    });
    final result = await DiagnosticSession.instance
        .runExclusive(
          () => BmwServiceManager.execute(
            item: item,
            link: udsLink,
            kwpLink: kwpLink,
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

  Widget _buildActuatorTab() => const RecoveredActuatorPanel();
}
