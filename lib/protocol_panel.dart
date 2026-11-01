import 'package:flutter/material.dart';
import 'diagnostic_session.dart';
import 'diagnostics/adapter_profile.dart';
import 'diagnostics/ecu_friendly_names.dart';
import 'diagnostics/protocol_setup.dart';
import 'diagnostics/uds_client.dart';
import 'diagnostics/recovered_ecu_keys.dart';

/// Advanced BMW diagnostic protocol and control unit addressing configuration.
class ProtocolPanel extends StatefulWidget {
  const ProtocolPanel({super.key});

  @override
  State<ProtocolPanel> createState() => _ProtocolPanelState();
}

class _ProtocolPanelState extends State<ProtocolPanel> {
  final _address = TextEditingController(text: '12');
  BmwUdsAdapterType _type = BmwUdsAdapterType.unknown;
  String? _ecuKey = 'cuX_BMSMP1';
  bool _busy = false;
  String? _status;

  @override
  void dispose() {
    _address.dispose();
    super.dispose();
  }

  Future<void> _configure() async {
    final value = int.tryParse(_address.text.trim(), radix: 16);
    if (value == null || value < 0 || value > 255) {
      setState(() =>
          _status = 'Enter a valid ECU address between 00 and FF hexadecimal.');
      return;
    }
    final shared = DiagnosticSession.instance;
    final session = shared.elmSession;
    if (session == null) {
      setState(() =>
          _status = 'Connect to an OBD adapter first before configuring protocol.');
      return;
    }
    if (shared.operationBusy) {
      setState(() =>
          _status = 'Wait for the active diagnostic operation to finish.');
      return;
    }
    final generation = shared.generation;
    shared.invalidateVehicleProtocol();
    setState(() {
      _busy = true;
      _status = 'Initializing adapter protocol…';
    });
    try {
      await shared.runExclusive(() async {
        final initialization = await initializeAdapter(session);
        shared.record(
            'Adapter initialized: ${initialization.profile.vendorLabel}');
        final link = BmwBikeUdsLink(session, adapterType: _type);
        if (!await link.configure(id: value)) {
          throw StateError('Adapter rejected BMW UDS configuration.');
        }
        shared.attachUdsClient(UdsClient(link),
            forGeneration: generation, link: link, ecuKey: _ecuKey);
      });
      if (mounted) {
        setState(() => _status =
            'BMW UDS configured for module at 0x${value.toRadixString(16).padLeft(2, '0').toUpperCase()} (${_ecuKey != null ? BmwEcuHelper.friendlyName(_ecuKey!) : "Custom"}).');
      }
    } catch (error) {
      if (mounted) setState(() => _status = error.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: DiagnosticSession.instance,
        builder: (context, _) => ExpansionTile(
          tilePadding: EdgeInsets.zero,
          title: const Text('Advanced Protocol & Module Addressing'),
          subtitle: const Text('Configure target ECU and diagnostic link'),
          children: [
            const Text(
              'Select a target control unit or enter an address to establish a direct diagnostic channel with the motorcycle.',
              style: TextStyle(color: Colors.white60, fontSize: 13),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<BmwUdsAdapterType>(
              initialValue: _type,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Adapter Hardware Architecture',
                border: OutlineInputBorder(),
              ),
              items: [
                for (final type in BmwUdsAdapterType.values)
                  DropdownMenuItem(value: type, child: Text(type.name)),
              ],
              onChanged: _busy ? null : (value) => setState(() => _type = value!),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _ecuKey,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Target Control Module',
                border: OutlineInputBorder(),
              ),
              items: [
                for (final key in recoveredEcuKeys)
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
                      setState(() {
                        _ecuKey = value;
                        if (value != null) {
                          final addr = BmwEcuHelper.standardAddress(value);
                          _address.text = addr
                              .toRadixString(16)
                              .padLeft(2, '0')
                              .toUpperCase();
                        }
                      });
                    },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _address,
              enabled: !_busy,
              maxLength: 2,
              decoration: const InputDecoration(
                labelText: 'Diagnostic Address (hex, e.g. 12 = Engine, 28 = ABS, 60 = Cluster)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: _busy || !DiagnosticSession.instance.connected
                  ? null
                  : _configure,
              child: Text(_busy ? 'Configuring…' : 'Configure Diagnostic Link'),
            ),
            if (_status != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  _status!,
                  style: const TextStyle(fontSize: 12.5),
                ),
              ),
          ],
        ),
      );
}
