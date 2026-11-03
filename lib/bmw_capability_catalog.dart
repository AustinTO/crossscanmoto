import 'package:flutter/material.dart';

import 'diagnostic_session.dart';
import 'diagnostics/source_qualified_catalog.dart';
import 'diagnostics/typed_service_step.dart';

const _lime = Color(0xFFBCEB58);
const _panel = Color(0xFF14191B);
const _ink = Color(0xFF0A0D0E);
const _muted = Color(0xFF929B9B);

/// Interactive BMW Motorrad capability catalog exposing chassis models,
/// ECU network topology, executable service routines, actuators, and adaptations.
class BmwCapabilityCatalogBrowser extends StatefulWidget {
  const BmwCapabilityCatalogBrowser({super.key, this.catalog});

  final SourceQualifiedCatalog? catalog;

  @override
  State<BmwCapabilityCatalogBrowser> createState() => _BmwCapabilityCatalogBrowserState();
}

// Backwards compatibility alias
typedef BiketuneCatalogBrowser = BmwCapabilityCatalogBrowser;

class _BmwCapabilityCatalogBrowserState extends State<BmwCapabilityCatalogBrowser> {
  SourceQualifiedCatalog? _catalog;
  bool _loading = true;
  String? _selectedEbr;
  final Set<String> _expandedEcus = {};

  @override
  void initState() {
    super.initState();
    if (widget.catalog != null) {
      _catalog = widget.catalog;
      _loading = false;
      _initSelectedBike(widget.catalog!);
    } else {
      _loadCatalog();
    }
  }

  void _initSelectedBike(SourceQualifiedCatalog cat) {
    final profile = DiagnosticSession.instance.profile;
    if (profile.ebr != null && cat.getBike(profile.ebr!) != null) {
      _selectedEbr = profile.ebr!.toUpperCase();
    } else if (cat.getBike('K50') != null) {
      _selectedEbr = 'K50';
    } else if (cat.bikes.isNotEmpty) {
      _selectedEbr = cat.bikes.first.ebr.toUpperCase();
    }
  }

  Future<void> _loadCatalog() async {
    try {
      final cat = await SourceQualifiedCatalog.load();
      if (!mounted) return;
      setState(() {
        _catalog = cat;
        _loading = false;
        _initSelectedBike(cat);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: _lime));
    }

    final cat = _catalog;
    if (cat == null) {
      return const Center(
        child: Text(
          'Capability catalog unavailable',
          style: TextStyle(color: Colors.white70),
        ),
      );
    }

    final selectedBike = _selectedEbr != null ? cat.getBike(_selectedEbr!) : null;
    final variants = _selectedEbr != null ? cat.getVariants(_selectedEbr!) : <BmwExtendedVariant>[];
    final ecuNames = _selectedEbr != null ? cat.getEcuNamesForBike(_selectedEbr!) : <String>[];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Header Banner
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF142017),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _lime.withValues(alpha: 0.5)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.verified_outlined, color: _lime, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'BMW Motorrad Factory Capabilities',
                      style: TextStyle(
                        color: _lime,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Native extended diagnostic library covering ${cat.bikes.length} chassis architectures, '
                      '${cat.ecus.length} ECUs, ${cat.serviceFunctions.length} service routines, '
                      '${cat.actuators.length} actuators, and ${cat.adaptations.length} adaptations.',
                      style: const TextStyle(color: Colors.white70, fontSize: 12, height: 1.35),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Chassis Selection Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _panel,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Motorcycle Architecture',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _lime.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${cat.bikes.length} Chassis Codes',
                      style: const TextStyle(
                        color: _lime,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                isExpanded: true,
                initialValue: _selectedEbr,
                dropdownColor: _panel,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: _ink,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Colors.white24),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Colors.white12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: _lime),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                items: cat.bikes.map((b) {
                  final years = (b.yearBegin != null && b.yearEnd != null)
                      ? ' (${b.yearBegin}–${b.yearEnd})'
                      : (b.yearBegin != null ? ' (${b.yearBegin}+)' : '');
                  return DropdownMenuItem<String>(
                    value: b.ebr.toUpperCase(),
                    child: Text(
                      '${b.ebr} · ${b.modelName}$years',
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: (newEbr) {
                  setState(() {
                    _selectedEbr = newEbr;
                    _expandedEcus.clear();
                  });
                },
              ),
              if (selectedBike != null) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _buildChip('Series', selectedBike.series),
                    _buildChip('Protocol', selectedBike.protocol),
                    if (selectedBike.seriesGroup != null)
                      _buildChip('Group', selectedBike.seriesGroup!),
                    if (selectedBike.platformId != null)
                      _buildChip('Platform', 'Platform ${selectedBike.platformId}'),
                    _buildChip('Variants', '${variants.length} factory VDS codes'),
                    _buildChip('ECUs', '${ecuNames.length} mapped modules'),
                  ],
                ),
                if (variants.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    'Variant Codes: ${variants.map((v) => v.variantCode).join(', ')}',
                    style: const TextStyle(color: _muted, fontSize: 11, fontFamily: 'monospace'),
                  ),
                ],
              ],
            ],
          ),
        ),

        const SizedBox(height: 18),

        // Mapped ECUs Section
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Supported ECUs (${ecuNames.length})',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
            if (selectedBike != null)
              Text(
                'Chassis ${selectedBike.ebr}',
                style: const TextStyle(color: _lime, fontSize: 11, fontWeight: FontWeight.bold),
              ),
          ],
        ),
        const SizedBox(height: 10),

        if (ecuNames.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _panel,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white10),
            ),
            child: const Center(
              child: Text(
                'No ECUs mapped for this chassis.',
                style: TextStyle(color: _muted, fontSize: 13),
              ),
            ),
          )
        else
          for (final ecuName in ecuNames) ...[
            _buildEcuCard(cat, ecuName),
          ],
      ],
    );
  }

  Widget _buildChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _ink,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$label: ', style: const TextStyle(color: _muted, fontSize: 11)),
          Text(
            value,
            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildEcuCard(SourceQualifiedCatalog cat, String ecuName) {
    final ecu = cat.getEcu(ecuName);
    final functions = cat.getServiceFunctions(ecuName);
    final actuators = cat.getActuators(ecuName);
    final adaptations = cat.getAdaptations(ecuName);
    final isExpanded = _expandedEcus.contains(ecuName);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: _panel,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () {
              setState(() {
                if (isExpanded) {
                  _expandedEcus.remove(ecuName);
                } else {
                  _expandedEcus.add(ecuName);
                }
              });
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: _ink,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: _lime.withValues(alpha: 0.3)),
                    ),
                    child: Center(
                      child: Text(
                        ecu?.hexAddress ?? 'UDS',
                        style: const TextStyle(
                          color: _lime,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ecuName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (ecu != null && ecu.description.isNotEmpty)
                          Text(
                            ecu.description,
                            style: const TextStyle(color: _muted, fontSize: 11),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  Wrap(
                    spacing: 6,
                    children: [
                      if (functions.isNotEmpty)
                        _buildCountBadge('${functions.length} routines', Icons.build_circle_outlined, _lime),
                      if (actuators.isNotEmpty)
                        _buildCountBadge('${actuators.length} actuators', Icons.tune, Colors.cyanAccent),
                      if (adaptations.isNotEmpty)
                        _buildCountBadge('${adaptations.length} adapts', Icons.restart_alt, Colors.orangeAccent),
                    ],
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: Colors.white54,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded) ...[
            const Divider(height: 1, color: Colors.white10),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (ecu?.cafdRoot != null) ...[
                    Row(
                      children: [
                        const Text('CAFD Root: ', style: TextStyle(color: _muted, fontSize: 11)),
                        Text(
                          ecu!.cafdRoot!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Service Functions / Routines
                  if (functions.isNotEmpty) ...[
                    const Text(
                      'SERVICE FUNCTIONS & ROUTINES',
                      style: TextStyle(color: _muted, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1),
                    ),
                    const SizedBox(height: 8),
                    for (final fn in functions) ...[
                      InkWell(
                        onTap: () {
                          final steps = cat.getServiceSteps(fn.id);
                          _showServiceFunctionDetail(fn, steps);
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 6),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: _ink,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      fn.label,
                                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                                    ),
                                    Text(
                                      '${fn.category} · ${cat.getServiceSteps(fn.id).length} step(s)',
                                      style: const TextStyle(color: _muted, fontSize: 10),
                                    ),
                                  ],
                                ),
                              ),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: fn.disabled ? Colors.redAccent.withValues(alpha: 0.15) : _lime.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      fn.disabled ? 'DISABLED' : 'EXECUTE',
                                      style: TextStyle(
                                        color: fn.disabled ? Colors.redAccent : _lime,
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  const Icon(Icons.chevron_right, size: 16, color: Colors.white38),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],

                  // Actuators Section
                  if (actuators.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    const Text(
                      'ACTUATORS & IO CONTROLS',
                      style: TextStyle(color: _muted, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1),
                    ),
                    const SizedBox(height: 6),
                    for (final a in actuators)
                      InkWell(
                        onTap: () => _showActuatorDetail(a),
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: _ink,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(a.label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
                                    if (a.requestPdu != null)
                                      Text(
                                        'Request: ${a.requestPdu}',
                                        style: const TextStyle(color: Colors.cyanAccent, fontSize: 9, fontFamily: 'monospace'),
                                      ),
                                  ],
                                ),
                              ),
                              FilledButton.tonal(
                                style: FilledButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                onPressed: () => _showActuatorDetail(a),
                                child: const Text('Actuate', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],

                  // Adaptations Section
                  if (adaptations.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    const Text(
                      'ADAPTATIONS & RESETS',
                      style: TextStyle(color: _muted, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1),
                    ),
                    const SizedBox(height: 6),
                    for (final ad in adaptations)
                      InkWell(
                        onTap: () => _showAdaptationDetail(ad),
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: _ink,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(ad.label ?? ad.adaptationId, style: const TextStyle(color: Colors.white70, fontSize: 11)),
                                    if (ad.resetPdu != null)
                                      Text(
                                        'Reset: ${ad.resetPdu}',
                                        style: const TextStyle(color: Colors.orangeAccent, fontSize: 9, fontFamily: 'monospace'),
                                      ),
                                  ],
                                ),
                              ),
                              FilledButton.tonal(
                                style: FilledButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                onPressed: () => _showAdaptationDetail(ad),
                                child: const Text('Reset', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showActuatorDetail(BmwExtendedActuator actuator) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: _panel,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) {
          final session = DiagnosticSession.instance;
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          actuator.label,
                          style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white54),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'ECU: ${actuator.ecuName} · Actuator ID: ${actuator.actuatorId}',
                    style: const TextStyle(color: _muted, fontSize: 12),
                  ),
                  const SizedBox(height: 14),
                  if (actuator.requestPdu != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _ink,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Request PDU:', style: TextStyle(color: _muted, fontSize: 10, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text(
                            actuator.requestPdu!,
                            style: const TextStyle(color: Colors.cyanAccent, fontSize: 12, fontFamily: 'monospace'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(backgroundColor: _lime, foregroundColor: Colors.black),
                          onPressed: () async {
                            if (!session.connected || session.udsClient == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Connect an OBD adapter to activate components.')),
                              );
                              return;
                            }
                            final pdus = TypedServiceStepExecutor.parsePduList(actuator.requestPdu);
                            if (pdus.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('No executable PDU available for this actuator.')),
                              );
                              return;
                            }
                            try {
                              for (final p in pdus) {
                                await session.udsClient!.link.request(p);
                              }
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Actuator "${actuator.label}" activated successfully!')),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Actuation failed: $e')),
                                );
                              }
                            }
                          },
                          icon: const Icon(Icons.play_arrow, size: 18),
                          label: const Text('Start Actuation', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showAdaptationDetail(BmwExtendedAdaptation adaptation) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _panel,
        title: Text('Reset ${adaptation.label ?? adaptation.adaptationId}?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ECU: ${adaptation.ecuName}\n'
              'Adaptation ID: ${adaptation.adaptationId}\n'
              '${adaptation.description ?? "This will reset the saved adaptation values in the ECU to factory baselines."}',
              style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
            ),
            if (adaptation.resetPdu != null) ...[
              const SizedBox(height: 12),
              Text(
                'Reset PDU: ${adaptation.resetPdu}',
                style: const TextStyle(color: Colors.orangeAccent, fontSize: 11, fontFamily: 'monospace'),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.amber, foregroundColor: Colors.black),
            onPressed: () async {
              Navigator.pop(context);
              final session = DiagnosticSession.instance;
              if (!session.connected || session.udsClient == null) {
                ScaffoldMessenger.of(this.context).showSnackBar(
                  const SnackBar(content: Text('Connect an OBD adapter to reset adaptations.')),
                );
                return;
              }
              final pdus = TypedServiceStepExecutor.parsePduList(adaptation.resetPdu);
              if (pdus.isEmpty) {
                ScaffoldMessenger.of(this.context).showSnackBar(
                  const SnackBar(content: Text('No executable reset PDU available for this adaptation.')),
                );
                return;
              }
              try {
                for (final p in pdus) {
                  await session.udsClient!.link.request(p);
                }
                if (this.context.mounted) {
                  ScaffoldMessenger.of(this.context).showSnackBar(
                    SnackBar(content: Text('Adaptation "${adaptation.label ?? adaptation.adaptationId}" reset successfully!')),
                  );
                }
              } catch (e) {
                if (this.context.mounted) {
                  ScaffoldMessenger.of(this.context).showSnackBar(
                    SnackBar(content: Text('Adaptation reset failed: $e')),
                  );
                }
              }
            },
            child: const Text('Confirm Reset'),
          ),
        ],
      ),
    );
  }

  void _showServiceFunctionDetail(BmwExtendedServiceFunction fn, List<BmwExtendedServiceStep> steps) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: _panel,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => FractionallySizedBox(
          heightFactor: 0.85,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        fn.label,
                        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white54),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${fn.ecuName} · ${steps.length} sequential step(s)',
                  style: const TextStyle(color: _muted, fontSize: 11),
                ),
                const SizedBox(height: 12),
                const Divider(height: 1, color: Colors.white12),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView.builder(
                    itemCount: steps.length,
                    itemBuilder: (context, index) {
                      final step = steps[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _ink,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Step ${step.stepOrder} • ${step.kind.toUpperCase()}',
                                  style: const TextStyle(
                                    color: _lime,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    step.readiness.name,
                                    style: const TextStyle(color: Colors.white70, fontSize: 9),
                                  ),
                                ),
                              ],
                            ),
                            if (step.text != null && step.text!.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text(
                                step.text!,
                                style: const TextStyle(color: Colors.white, fontSize: 12, height: 1.3),
                              ),
                            ],
                            if (step.requestPdu != null && step.requestPdu!.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text(
                                'Request: ${step.requestPdu}',
                                style: const TextStyle(color: Colors.cyanAccent, fontSize: 10, fontFamily: 'monospace'),
                              ),
                            ],
                            if (step.stopPdu != null && step.stopPdu!.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                'Stop: ${step.stopPdu}',
                                style: const TextStyle(color: Colors.orangeAccent, fontSize: 10, fontFamily: 'monospace'),
                              ),
                            ],
                            if (step.waitMs > 0) ...[
                              const SizedBox(height: 4),
                              Text(
                                'Duration / Wait: ${step.waitMs} ms',
                                style: const TextStyle(color: _muted, fontSize: 10),
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: _lime,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () async {
                      Navigator.pop(context);
                      await _executeServiceRoutine(fn, steps);
                    },
                    icon: const Icon(Icons.play_arrow, size: 18),
                    label: const Text('Execute Routine', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _executeServiceRoutine(BmwExtendedServiceFunction fn, List<BmwExtendedServiceStep> steps) async {
    final session = DiagnosticSession.instance;
    if (!session.connected || session.udsClient == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Connect an OBD adapter to execute service routines on the motorcycle.')),
        );
      }
      return;
    }

    final executor = TypedServiceStepExecutor(
      link: session.udsClient!.link,
      onPrompt: (prompt) async {
        return await showDialog<bool>(
              context: context,
              barrierDismissible: false,
              builder: (ctx) => AlertDialog(
                backgroundColor: _panel,
                title: const Text('Routine Operator Prompt'),
                content: Text(prompt, style: const TextStyle(color: Colors.white70)),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                  FilledButton(
                    style: FilledButton.styleFrom(backgroundColor: _lime, foregroundColor: Colors.black),
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text('Proceed'),
                  ),
                ],
              ),
            ) ??
            false;
      },
    );

    // Show progress dialog
    if (!mounted) return;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: _panel,
        title: Text('Executing ${fn.label}'),
        content: const Row(
          children: [
            CircularProgressIndicator(color: _lime),
            SizedBox(width: 16),
            Expanded(child: Text('Executing service routine steps...')),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              executor.cancel();
              Navigator.pop(ctx);
            },
            child: const Text('Cancel / Stop'),
          ),
        ],
      ),
    );

    final results = await executor.executeSequence(steps);
    if (mounted) {
      Navigator.of(context, rootNavigator: true).pop(); // dismiss progress dialog
      final allSuccess = results.every((r) => r.isSuccess);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            allSuccess
                ? 'Routine "${fn.label}" completed successfully (${results.length} step(s)).'
                : 'Routine finished: ${results.lastOrNull?.message ?? "Incomplete"}',
          ),
          backgroundColor: allSuccess ? const Color(0xFF1E2822) : Colors.red.shade900,
        ),
      );
    }
  }

  Widget _buildCountBadge(String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 12),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
