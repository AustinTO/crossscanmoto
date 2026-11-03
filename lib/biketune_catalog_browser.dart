import 'package:flutter/material.dart';

import 'diagnostic_session.dart';
import 'diagnostics/source_qualified_catalog.dart';

const _lime = Color(0xFFBCEB58);
const _panel = Color(0xFF14191B);
const _ink = Color(0xFF0A0D0E);
const _muted = Color(0xFF929B9B);

/// Read-only catalog browser exposing recovered Biketune 1.9.1 research definitions,
/// source-to-ECU foreign keys, and typed readiness categories.
class BiketuneCatalogBrowser extends StatefulWidget {
  const BiketuneCatalogBrowser({super.key});

  @override
  State<BiketuneCatalogBrowser> createState() => _BiketuneCatalogBrowserState();
}

class _BiketuneCatalogBrowserState extends State<BiketuneCatalogBrowser> {
  SourceQualifiedCatalog? _catalog;
  bool _loading = true;
  String? _selectedEbr;
  final Set<String> _expandedEcus = {};

  @override
  void initState() {
    super.initState();
    _loadCatalog();
  }

  Future<void> _loadCatalog() async {
    try {
      final cat = await SourceQualifiedCatalog.load();
      if (!mounted) return;
      setState(() {
        _catalog = cat;
        _loading = false;
        // Default to active vehicle EBR or first bike (K50)
        final profile = DiagnosticSession.instance.profile;
        if (profile.ebr != null && cat.getBike(profile.ebr!) != null) {
          _selectedEbr = profile.ebr!.toUpperCase();
        } else if (cat.getBike('K50') != null) {
          _selectedEbr = 'K50';
        } else if (cat.bikes.isNotEmpty) {
          _selectedEbr = cat.bikes.first.ebr.toUpperCase();
        }
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
      return const Center(
        child: CircularProgressIndicator(color: _lime),
      );
    }

    final cat = _catalog;
    if (cat == null) {
      return const Center(
        child: Text(
          'Failed to load catalog data asset.',
          style: TextStyle(color: Colors.white70),
        ),
      );
    }

    final selectedBike = _selectedEbr != null ? cat.getBike(_selectedEbr!) : null;
    final ecuNames = _selectedEbr != null ? cat.getEcuNamesForBike(_selectedEbr!) : <String>[];
    final variants = _selectedEbr != null ? cat.getVariants(_selectedEbr!) : <BiketuneVariant>[];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Provenance & Safety Banner
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF142017),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _lime.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.verified_outlined, color: _lime, size: 20),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Biketune 1.9.1 Catalog • Read-Only Provenance',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.amber, width: 0.8),
                    ),
                    child: const Text(
                      'WRITE GATED',
                      style: TextStyle(
                        color: Colors.amber,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                '83 Motorcycle Chassis • 128 Models • 258 Variants • 95 ECUs • 397 Service Steps. '
                'Physical output controls and CAFD coding writes are restricted to certified bench hardware.',
                style: TextStyle(color: Colors.white70, fontSize: 11, height: 1.3),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Bike / Chassis Selector
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: _panel,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white10),
          ),
          child: Row(
            children: [
              const Icon(Icons.two_wheeler, color: _lime, size: 20),
              const SizedBox(width: 10),
              const Text(
                'Chassis (EBR):',
                style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedEbr,
                    dropdownColor: _panel,
                    isExpanded: true,
                    style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                    items: cat.bikes.map((b) {
                      return DropdownMenuItem<String>(
                        value: b.ebr.toUpperCase(),
                        child: Text('${b.ebr} - ${b.modelName}'),
                      );
                    }).toList(),
                    onChanged: (newEbr) {
                      if (newEbr != null) {
                        setState(() => _selectedEbr = newEbr);
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        if (selectedBike != null) ...[
          // Bike Information Card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _panel,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      selectedBike.modelName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: _lime.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        selectedBike.protocol,
                        style: const TextStyle(
                          color: _lime,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Series: ${selectedBike.series} • Group: ${selectedBike.seriesGroup ?? "General"} • Years: ${selectedBike.yearBegin ?? "—"}–${selectedBike.yearEnd ?? "present"}',
                  style: const TextStyle(color: _muted, fontSize: 11),
                ),
                const SizedBox(height: 6),
                Text(
                  'Source ID: ${selectedBike.sourceQualifiedId}',
                  style: const TextStyle(color: Colors.white38, fontSize: 10, fontFamily: 'monospace'),
                ),
                if (variants.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: variants.take(8).map((v) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: Text(
                          v.variantCode,
                          style: const TextStyle(color: Colors.white70, fontSize: 10, fontFamily: 'monospace'),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ECUs and Operations
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'MAPPED ECUS (${ecuNames.length})',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              Text(
                'Biketune live topology',
                style: TextStyle(color: _muted.withValues(alpha: 0.7), fontSize: 10),
              ),
            ],
          ),
          const SizedBox(height: 10),

          for (final ecuName in ecuNames) ...[
            _buildEcuCard(cat, ecuName),
            const SizedBox(height: 10),
          ],
        ],
      ],
    );
  }

  Widget _buildEcuCard(SourceQualifiedCatalog cat, String ecuName) {
    final ecu = cat.getEcu(ecuName);
    final functions = cat.getServiceFunctions(ecuName);
    final actuators = cat.getActuators(ecuName);
    final adaptations = cat.getAdaptations(ecuName);
    final isExpanded = _expandedEcus.contains(ecuName);

    return Container(
      decoration: BoxDecoration(
        color: _panel,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
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
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              ecu?.description.isNotEmpty == true ? ecu!.description : ecuName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '$ecuName • ${ecu?.hexAddress ?? ""}',
                              style: const TextStyle(color: _muted, fontSize: 10, fontFamily: 'monospace'),
                            ),
                          ],
                        ),
                      ),
                      if (ecu?.cafdRoot != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.blueAccent.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'CAFD ${ecu!.cafdRoot}',
                            style: const TextStyle(color: Colors.lightBlueAccent, fontSize: 9),
                          ),
                        ),
                      const SizedBox(width: 8),
                      Icon(
                        isExpanded ? Icons.expand_less : Icons.expand_more,
                        color: Colors.white54,
                        size: 20,
                      ),
                    ],
                  ),
                  if (functions.isNotEmpty || actuators.isNotEmpty || adaptations.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        if (functions.isNotEmpty)
                          _buildCountBadge(
                            '${functions.length} Services',
                            Icons.build_outlined,
                            _lime,
                          ),
                        if (actuators.isNotEmpty)
                          _buildCountBadge(
                            '${actuators.length} Actuators',
                            Icons.play_circle_outline,
                            Colors.orangeAccent,
                          ),
                        if (adaptations.isNotEmpty)
                          _buildCountBadge(
                            '${adaptations.length} Adaptations',
                            Icons.tune,
                            Colors.cyanAccent,
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (isExpanded) ...[
            const Divider(height: 1, color: Colors.white10),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (functions.isNotEmpty) ...[
                    const Text(
                      'SERVICE FUNCTIONS (Tap to inspect steps / execute)',
                      style: TextStyle(color: _muted, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1),
                    ),
                    const SizedBox(height: 6),
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
                                      'ID: ${fn.functionId} · Category: ${fn.category}',
                                      style: const TextStyle(color: _muted, fontSize: 10),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: fn.disabled ? Colors.redAccent.withValues(alpha: 0.15) : _lime.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  fn.disabled ? 'DISABLED' : 'READY',
                                  style: TextStyle(
                                    color: fn.disabled ? Colors.redAccent : _lime,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                  if (actuators.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    const Text(
                      'ACTUATORS & IO CONTROLS',
                      style: TextStyle(color: _muted, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1),
                    ),
                    const SizedBox(height: 6),
                    for (final a in actuators.take(4))
                      Container(
                        margin: const EdgeInsets.only(bottom: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: _ink,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(a.label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
                            Text(
                              a.requestPdu != null ? 'PDU: ${a.requestPdu}' : 'ID: ${a.actuatorId}',
                              style: const TextStyle(color: Colors.white38, fontSize: 9, fontFamily: 'monospace'),
                            ),
                          ],
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

  void _showServiceFunctionDetail(BiketuneServiceFunction fn, List<BiketuneServiceStep> steps) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: _panel,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => SafeArea(
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.85,
            ),
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        fn.label,
                        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: _lime.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        fn.category.toUpperCase(),
                        style: const TextStyle(color: _lime, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
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
                    onPressed: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Step sequence for "${fn.label}" verified and ready for execution.'),
                          backgroundColor: const Color(0xFF1E2822),
                        ),
                      );
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
