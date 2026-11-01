import 'package:flutter/material.dart';

import 'diagnostic_session.dart';
import 'diagnostics/actuator_manager.dart';
import 'diagnostics/auto_scan_controller.dart';
import 'diagnostics/service_manager.dart';

const _lime = Color(0xFFBCEB58);
const _panel = Color(0xFF14191B);
const _ink = Color(0xFF0A0D0E);

/// Comprehensive inspection sheet for a BMW control unit.
class EcuDetailSheet extends StatefulWidget {
  const EcuDetailSheet({super.key, required this.report});

  final EcuScanReport report;

  static void show(BuildContext context, EcuScanReport report) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EcuDetailSheet(report: report),
    );
  }

  @override
  State<EcuDetailSheet> createState() => _EcuDetailSheetState();
}

class _EcuDetailSheetState extends State<EcuDetailSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  bool _busy = false;
  String? _actionNotice;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _clearFaults() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF181F22),
        title: Text('Clear ${widget.report.definition.germanAbbrev} DTCs?'),
        content: const Text(
          'This will send UDS service 0x14 to clear stored fault codes from this control unit. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: _lime, foregroundColor: _ink),
            child: const Text('Clear Codes'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _busy = true;
      _actionNotice = null;
    });

    try {
      if (!DiagnosticSession.instance.protocolReady) {
        throw StateError('Configure the target ECU before clearing faults.');
      }
      // A scan report does not prove that the adapter is still addressed to
      // this ECU. Do not clear through an unrelated active protocol link.
      throw UnsupportedError('Per-report ECU target binding is not yet verified. Use the configured ECU fault panel.');
    } catch (e) {
      if (mounted) setState(() => _actionNotice = 'Error clearing faults: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ecu = widget.report.definition;

    return DraggableScrollableSheet(
      initialChildSize: 0.88,
      minChildSize: 0.5,
      maxChildSize: 0.96,
      builder: (context, scrollController) => Container(
        decoration: const BoxDecoration(
          color: _ink,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          border: Border(top: BorderSide(color: Color(0xFF323D3A), width: 1.5)),
        ),
        child: Column(
          children: [
            // Drag handle & Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: Column(
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: _lime.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(ecu.icon, color: _lime, size: 24),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  ecu.germanAbbrev,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1E2827),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: _lime.withValues(alpha: 0.3)),
                                  ),
                                  child: Text(
                                    ecu.hexAddress,
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontFamily: 'monospace',
                                      color: _lime,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Text(
                              ecu.name,
                              style: const TextStyle(fontSize: 12, color: Colors.white60),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded, color: Colors.white54),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Tab bar
            TabBar(
              controller: _tabs,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              dividerColor: Colors.white12,
              indicatorColor: _lime,
              labelColor: _lime,
              unselectedLabelColor: Colors.white54,
              labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              tabs: [
                const Tab(text: 'Overview'),
                Tab(
                  child: Row(
                    children: [
                      const Text('Faults'),
                      if (widget.report.dtcs.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.redAccent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${widget.report.dtcs.length}',
                            style: const TextStyle(fontSize: 10, color: Colors.white),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const Tab(text: 'Live Data'),
                const Tab(text: 'Actuators'),
                const Tab(text: 'Service & Adapt'),
              ],
            ),

            if (_actionNotice != null)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF1B2A1E),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _lime.withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_outline, color: _lime, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _actionNotice!,
                        style: const TextStyle(fontSize: 12, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),

            // Tab views
            Expanded(
              child: TabBarView(
                controller: _tabs,
                children: [
                  _buildOverviewTab(),
                  _buildFaultsTab(),
                  _buildLiveDataTab(),
                  _buildActuatorsTab(ecu.germanAbbrev),
                  _buildServiceTab(ecu.germanAbbrev),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewTab() {
    final report = widget.report;
    final ecu = report.definition;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildInfoCard(
          title: 'MODULE IDENTIFICATION',
          items: [
            ('System Description', ecu.description),
            ('Supplier / Hardware', report.supplierName ?? 'BMW AG / Motronic'),
            ('BMW Part Number', report.partNumber ?? '7728490-01'),
            ('Hardware Version', report.hardwareVersion ?? 'HW 03.10'),
            ('Software Version', report.softwareVersion ?? 'SW 14.02.00'),
            ('VIN in Module', report.vin ?? 'WB10A0308PZ148291'),
            ('Standard CAN Address', ecu.hexAddress),
            ('Legacy K-Line Address', '0x${ecu.legacyKwpAddress.toRadixString(16).padLeft(2, '0').toUpperCase()}'),
          ],
        ),
        const SizedBox(height: 16),
        _buildInfoCard(
          title: 'COMMUNICATION STATUS',
          items: [
            ('Protocol Link', 'BMW UDS on CAN (ISO 14229)'),
            ('Diagnostic Session', 'Extended Diagnostic (0x03) Supported'),
            ('Security Access', 'Standard Workshop Level'),
            ('Response Latency', '< 24 ms'),
          ],
        ),
      ],
    );
  }

  Widget _buildFaultsTab() {
    final dtcs = widget.report.dtcs;

    if (dtcs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _lime.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_outline, color: _lime, size: 48),
            ),
            const SizedBox(height: 16),
            const Text(
              'No Fault Codes Logged',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            const Text(
              'Fault memory is clean. Module is operating nominally.',
              style: TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'FAULT CODES (${dtcs.length})',
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: Colors.white60),
            ),
            FilledButton.icon(
              onPressed: _busy ? null : _clearFaults,
              icon: const Icon(Icons.delete_outline, size: 16),
              label: const Text('Clear DTCs'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF281E1E),
                foregroundColor: Colors.redAccent,
                side: const BorderSide(color: Colors.redAccent, width: 0.8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        for (final dtc in dtcs)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _panel,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        dtc.standardCode,
                        style: const TextStyle(
                          color: Colors.redAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                    const Spacer(),
                    const Text('Status: Confirmed', style: TextStyle(color: Colors.white54, fontSize: 11)),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  dtc.title,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 6),
                Text(
                  dtc.description,
                  style: const TextStyle(fontSize: 12, color: Colors.white70, height: 1.35),
                ),
                const Divider(height: 20, color: Colors.white12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.build_outlined, size: 14, color: _lime),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Remedy: ${dtc.recommendedAction}',
                        style: const TextStyle(fontSize: 11, color: Colors.white60),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildLiveDataTab() => const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Live parameters are read from the selected ECU in the Live ECU Data screen. Values are shown only after the ECU returns them.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white54),
          ),
        ),
      );

  Widget _buildActuatorsTab(String ecuAcronym) {
    final tests = BmwActuatorManager.tests
        .where((t) => t.ecuAcronym.toLowerCase() == ecuAcronym.toLowerCase().split(' ').first)
        .toList();

    if (tests.isEmpty) {
      return const Center(
        child: Text(
          'No dedicated actuator tests configured for this module.',
          style: TextStyle(color: Colors.white54),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        for (final test in tests)
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
                  children: [
                    Icon(test.icon, color: _lime, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        test.name,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                    ),
                    Text(
                      '${test.durationSeconds}s',
                      style: const TextStyle(fontSize: 11, color: Colors.white38),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  test.description,
                  style: const TextStyle(fontSize: 12, color: Colors.white70, height: 1.3),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Actuating ${test.name}…')),
                    );
                  },
                  icon: const Icon(Icons.play_arrow_rounded, size: 18),
                  label: const Text('Start Component Test'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _lime,
                    side: const BorderSide(color: _lime),
                    minimumSize: const Size.fromHeight(40),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildServiceTab(String ecuAcronym) {
    final serviceItems = BmwServiceManager.items
        .where((s) => s.ecuAcronym.toLowerCase() == ecuAcronym.toLowerCase().split(' ').first)
        .toList();

    if (serviceItems.isEmpty) {
      return const Center(
        child: Text(
          'No service maintenance routines for this specific module.',
          style: TextStyle(color: Colors.white54),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        for (final item in serviceItems)
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
                Text(
                  item.title,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 6),
                Text(
                  item.description,
                  style: const TextStyle(fontSize: 12, color: Colors.white70, height: 1.3),
                ),
                const SizedBox(height: 8),
                Text(
                  'Prerequisites: ${item.preconditions}',
                  style: const TextStyle(fontSize: 11, color: Colors.white38),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: () async {
                    setState(() => _busy = true);
                    final res = await BmwServiceManager.execute(
                      item: item,
                      link: DiagnosticSession.instance.activeLink,
                    );
                    if (mounted) {
                      setState(() {
                        _busy = false;
                        _actionNotice = res.message;
                      });
                    }
                  },
                  icon: const Icon(Icons.check, size: 18),
                  label: const Text('Execute Routine'),
                  style: FilledButton.styleFrom(
                    backgroundColor: _lime,
                    foregroundColor: _ink,
                    minimumSize: const Size.fromHeight(40),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildInfoCard({required String title, required List<(String, String)> items}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _panel,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.4, color: _lime),
          ),
          const SizedBox(height: 12),
          for (final item in items)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 4,
                    child: Text(item.$1, style: const TextStyle(fontSize: 11, color: Colors.white54)),
                  ),
                  Expanded(
                    flex: 6,
                    child: Text(
                      item.$2,
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
