import 'package:flutter/material.dart';
import 'diagnostic_session.dart';
import 'diagnostics/adapter_profile.dart';
import 'diagnostics/ecu_friendly_names.dart';
import 'diagnostics/protocol_setup.dart';
import 'diagnostics/recovered_actuators.dart';
import 'diagnostics/uds_client.dart';

const _panel = Color(0xFF13181B);
const _lime = Color(0xFFBCEB58);
const _muted = Color(0xFF929B9B);
const _edge = Color(0xFF293133);

/// Interactive component and actuator testing panel for BMW Motorrad control units.
class RecoveredActuatorPanel extends StatefulWidget {
  const RecoveredActuatorPanel({super.key});

  @override
  State<RecoveredActuatorPanel> createState() => _RecoveredActuatorPanelState();
}

// Alias for clean naming across the app
typedef ActuatorTestPanel = RecoveredActuatorPanel;

class _RecoveredActuatorPanelState extends State<RecoveredActuatorPanel> {
  bool _busy = false;
  String? _status;
  late String _selectedEcuKey;

  static const _supportedActuatorEcus = <String>[
    'cuX_BMSMP1',
    'cuX_ABS',
    'cuX_BMSO1',
    'cuX_BMSX',
    'cuX_BMSE2B',
  ];

  @override
  void initState() {
    super.initState();
    final currentKey = DiagnosticSession.instance.ecuDefinitionKey;
    if (currentKey != null &&
        (_supportedActuatorEcus.contains(currentKey) ||
            recoveredActuatorsByEcu.containsKey(currentKey))) {
      _selectedEcuKey = currentKey;
    } else {
      _selectedEcuKey = _supportedActuatorEcus.first;
    }
  }

  Future<void> _run(RecoveredActuatorPosition position) async {
    final shared = DiagnosticSession.instance;
    var client = shared.udsClient;
    final generation = shared.generation;

    // Auto-configure UDS link if connected to an adapter but link not yet attached
    if (client == null && shared.connected) {
      final session = shared.elmSession;
      if (session != null) {
        setState(() {
          _busy = true;
          _status = 'Connecting to ${BmwEcuHelper.friendlyName(_selectedEcuKey)}…';
        });
        try {
          final addr = BmwEcuHelper.standardAddress(_selectedEcuKey);
          await initializeAdapter(session);
          final link = BmwBikeUdsLink(session);
          if (await link.configure(id: addr)) {
            final newClient = UdsClient(link);
            shared.attachUdsClient(
              newClient,
              forGeneration: generation,
              link: link,
              ecuKey: _selectedEcuKey,
            );
            client = newClient;
          }
        } catch (e) {
          if (mounted) setState(() => _status = 'Connection failed: $e');
        } finally {
          if (mounted) setState(() => _busy = false);
        }
      }
    }

    if (client == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Connect to your OBD adapter in the Adapter tab to execute live component tests.',
            ),
            backgroundColor: Color(0xFF1E2628),
          ),
        );
      }
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _panel,
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: _lime, size: 24),
            const SizedBox(width: 10),
            Expanded(child: Text('Activate ${position.title}?')),
          ],
        ),
        content: Text(
          '${position.instruction}\n\n'
          'WORKSHOP SAFETY WARNING: The connected component may move, energize, or start. '
          'Ensure the motorcycle is stationary on its stand, engine off, ignition on, and all personnel are clear.\n\n'
          'Activation will automatically stop after ${position.activation?.durationSeconds ?? 0} seconds.',
          style: const TextStyle(fontSize: 13, height: 1.4, color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: _lime, foregroundColor: Colors.black),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirm & Activate'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() {
      _busy = true;
      _status = 'Activating ${position.title}…';
    });

    try {
      await shared.runExclusive(() => RecoveredActuatorExecutor().run(
            link: _CurrentLink(client!.link, generation, _selectedEcuKey),
            position: position,
          ));
      if (mounted) {
        setState(() => _status = 'Activation sequence acknowledged and completed safely.');
      }
    } catch (error) {
      if (mounted) setState(() => _status = error.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
        canPop: !_busy,
        child: ListenableBuilder(
          listenable: DiagnosticSession.instance,
          builder: (context, _) {
            final shared = DiagnosticSession.instance;
            final definitions = recoveredActuatorsByEcu[_selectedEcuKey] ??
                const <RecoveredActuatorDefinition>[];

            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _panel,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _edge),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Target Subsystem',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Select a control unit to view and trigger bi-directional component tests.',
                        style: TextStyle(color: _muted, fontSize: 12),
                      ),
                      const SizedBox(height: 14),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedEcuKey,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Control Unit',
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          for (final key in _supportedActuatorEcus)
                            DropdownMenuItem(
                              value: key,
                              child: Text(
                                BmwEcuHelper.friendlyName(key),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                        ],
                        onChanged: _busy
                            ? null
                            : (value) {
                                if (value != null) {
                                  setState(() {
                                    _selectedEcuKey = value;
                                    _status = null;
                                  });
                                  shared.ecuDefinitionKey = value;
                                }
                              },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                if (_status != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: _status!.contains('acknowledged')
                          ? const Color(0xFF132A18)
                          : const Color(0xFF281C1D),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _status!.contains('acknowledged')
                            ? _lime.withValues(alpha: 0.5)
                            : Colors.redAccent.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _status!.contains('acknowledged')
                              ? Icons.check_circle_outline
                              : Icons.info_outline,
                          color: _status!.contains('acknowledged')
                              ? _lime
                              : Colors.redAccent,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _status!,
                            style: const TextStyle(fontSize: 12.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (definitions.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: Center(
                      child: Text(
                        'No component tests available for the selected module.',
                        style: TextStyle(color: _muted),
                      ),
                    ),
                  ),
                for (final definition in definitions)
                  Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _panel,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: _edge),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.tune, color: _lime, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              definition.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        for (final position in definition.positions)
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(position.title,
                                style: const TextStyle(fontSize: 14)),
                            subtitle: Text(
                              position.instruction,
                              style: const TextStyle(
                                color: _muted,
                                fontSize: 12,
                              ),
                            ),
                            trailing: IconButton.filledTonal(
                              style: IconButton.styleFrom(
                                backgroundColor: _lime.withValues(alpha: 0.15),
                                foregroundColor: _lime,
                              ),
                              tooltip: 'Activate ${position.title}',
                              icon: const Icon(Icons.play_arrow, size: 20),
                              onPressed: _busy ||
                                      shared.operationBusy ||
                                      !position.isSupported
                                  ? null
                                  : () => _run(position),
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
            );
          },
        ),
      );
}

class _CurrentLink implements UdsRequestLink {
  _CurrentLink(this.link, this.generation, this.ecuKey);
  final UdsRequestLink link;
  final int generation;
  final String ecuKey;

  @override
  Future<List<int>> request(List<int> payload, {Duration? timeout}) {
    final shared = DiagnosticSession.instance;
    if (shared.generation != generation ||
        !identical(shared.udsClient?.link, link)) {
      throw StateError('The ECU connection changed; actuator request cancelled.');
    }
    return link.request(payload, timeout: timeout);
  }
}
