import 'package:flutter/material.dart';

import 'app_navigation.dart';
import 'diagnostic_session.dart';
import 'protocol_panel.dart';
import 'ble_picker.dart';
import 'diagnostics/connect.dart';
import 'diagnostics/elm_session.dart';
import 'diagnostics/bluetooth_transport.dart';
import 'diagnostics/adapter_profile.dart';
import 'diagnostics/adapter_relay.dart';
import 'relay_page.dart';

class AdapterPage extends StatefulWidget {
  const AdapterPage({super.key});
  @override
  State<AdapterPage> createState() => _AdapterPageState();
}

class _AdapterPageState extends State<AdapterPage> {
  final _host = TextEditingController();
  final _port = TextEditingController(text: '35000');
  final _form = GlobalKey<FormState>();
  ElmSession? _session;
  bool _busy = false;
  String? _error;
  String? _identity;
  String? _voltage;
  final List<String> _transcript = [];

  @override
  void initState() {
    super.initState();
    _readSharedSession();
    DiagnosticSession.instance.addListener(_sessionChanged);
    AdapterRelayCoordinator.addListener(_sessionChanged);
  }

  void _readSharedSession() {
    final shared = DiagnosticSession.instance;
    _session = shared.elmSession;
    _identity = shared.identity;
    _voltage = shared.voltage;
  }

  void _sessionChanged() {
    if (mounted) setState(_readSharedSession);
  }

  Future<void> _connect({PairedBluetoothDevice? device, AdapterTransport? preparedTransport}) async {
    if (DiagnosticSession.instance.operationBusy) {
      await preparedTransport?.close();
      if (mounted) setState(() => _error='Wait for the active diagnostic operation to finish.');
      return;
    }
    if (AdapterRelayCoordinator.isHosting) {
      await preparedTransport?.close();
      if (mounted) setState(() => _error = 'Stop the adapter relay before connecting directly.');
      return;
    }
    if (device == null && preparedTransport == null && !_form.currentState!.validate()) return;
    setState(() { _busy = true; _error = null; _transcript.clear(); });
    ElmSession? candidate;
    try {
      candidate = ElmSession(preparedTransport ?? (device == null
          ? await connectAdapter(_host.text.trim(), int.parse(_port.text))
          : await BluetoothAdapterTransport.connect(device)));
      final profile = await identifyAdapter(candidate);
      final identity = profile.ati;
      if (identity.isError || identity.lines.isEmpty) throw StateError('Adapter did not return an identity');
      _transcript.add('ATI → ${identity.text}');
      for (final response in [profile.atHash1, profile.stdi, profile.atAt1]) {
        if (response != null) _transcript.add('${response.command} → ${response.text}');
      }
      _transcript.add('Adapter family: ${profile.vendorLabel}');
      final voltage = await candidate.command('ATRV');
      _transcript.add('ATRV → ${voltage.text}');
      if (!mounted) { await candidate.close(); return; }
      DiagnosticSession.instance.attach(candidate, identity: identity.text, voltage: voltage.isError ? null : voltage.text);
      for (final entry in _transcript) { DiagnosticSession.instance.record(entry); }
      setState(() { _session = candidate; _identity = identity.text; _voltage = voltage.isError ? null : voltage.text; });
    } catch (error) {
      await candidate?.close();
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _chooseBle() async {
    setState(() { _busy = true; _error = null; });
    try {
      final transport = await chooseBleAdapter(context);
      if (transport != null) {
        if (!mounted) { await transport.close(); return; }
        await _connect(preparedTransport: transport);
      }
    } catch (error) { if (mounted) setState(() => _error = error.toString()); }
    finally { if (mounted) setState(() => _busy = false); }
  }

  Future<void> _chooseBluetooth() async {
    setState(() { _busy = true; _error = null; });
    try {
      final devices = await BluetoothAdapterTransport.pairedDevices();
      if (!mounted) return;
      final selected = await showModalBottomSheet<PairedBluetoothDevice>(
        context: context, showDragHandle: true,
        builder: (context) => SafeArea(child: ListView(shrinkWrap: true, children: [
          const ListTile(title: Text('Paired adapters'), subtitle: Text('Pair your adapter in Android Bluetooth settings first.')),
          if (devices.isEmpty) const ListTile(title: Text('No paired devices found')),
          for (final device in devices) ListTile(leading: const Icon(Icons.bluetooth), title: Text(device.name), subtitle: Text(device.address), onTap: () => Navigator.pop(context, device)),
        ])),
      );
      if (selected != null && mounted) await _connect(device: selected);
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _disconnect() async {
    if (DiagnosticSession.instance.operationBusy) { setState(() => _error='Wait for the active diagnostic operation to finish.'); return; }
    final session = _session;
    DiagnosticSession.instance.detach();
    setState(() { _session = null; _identity = null; _voltage = null; });
    await session?.close();
  }

  @override
  void dispose() {
    DiagnosticSession.instance.removeListener(_sessionChanged);
    AdapterRelayCoordinator.removeListener(_sessionChanged);
    _host.dispose(); _port.dispose(); super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(24),
    children: [
      const Text('Connect your workshop', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700)),
      const SizedBox(height: 8),
      const Text('Wi-Fi or paired Bluetooth diagnostic adapter', style: TextStyle(color: Colors.white60)),
      const SizedBox(height: 24),
      Card(child: Padding(padding: const EdgeInsets.all(22), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(_session == null ? Icons.wifi_find : Icons.wifi, size: 36, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 16),
        Text(_identity ?? 'Ready to connect', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Text(_session == null ? 'Join your adapter’s Wi-Fi network, then enter its address.' : 'Adapter connected • ${_voltage ?? 'Voltage unavailable'}', style: const TextStyle(color: Colors.white60)),
        const SizedBox(height: 24),
        Form(key: _form, child: Column(children: [
          TextFormField(controller: _host, enabled: !_busy && _session == null, decoration: const InputDecoration(labelText: 'Adapter address', hintText: '192.168.0.10', border: OutlineInputBorder()), validator: (value) => value == null || value.trim().isEmpty ? 'Enter an address' : null),
          const SizedBox(height: 16),
          TextFormField(controller: _port, enabled: !_busy && _session == null, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Port', border: OutlineInputBorder()), validator: (value) { final port = int.tryParse(value ?? ''); return port == null || port < 1 || port > 65535 ? 'Enter a port from 1 to 65535' : null; }),
        ])),
        const SizedBox(height: 20),
        SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: _busy ? null : _session == null ? () => _connect() : _disconnect, icon: Icon(_session == null ? Icons.link : Icons.link_off), label: Text(_busy ? 'Connecting…' : _session == null ? 'Connect adapter' : 'Disconnect'))),
        if (_error != null) Padding(padding: const EdgeInsets.only(top: 16), child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error))),
      ]))),
      if (Theme.of(context).platform == TargetPlatform.android && _session == null)
        OutlinedButton.icon(onPressed: _busy || AdapterRelayCoordinator.isHosting ? null : _chooseBluetooth, icon: const Icon(Icons.bluetooth), label: const Text('Choose paired Bluetooth adapter')),
      const SizedBox(height: 24),
      if (Theme.of(context).platform == TargetPlatform.iOS && _session == null)
        OutlinedButton.icon(onPressed: _busy ? null : _chooseBle, icon: const Icon(Icons.bluetooth_searching), label: const Text('Discover BLE adapter')),
      OutlinedButton.icon(
        onPressed: _busy ? null : () => appPush(context, const RelayPage()),
        icon: const Icon(Icons.hub_outlined),
        label: const Text('Android adapter relay'),
      ),
      if (AdapterRelayCoordinator.isHosting)
        const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Text('Relay active. Stop it before opening a direct adapter connection.')),
      const ProtocolPanel(),
      const SizedBox(height: 24),
      const Text('CONNECTION ACTIVITY', style: TextStyle(fontSize: 11, letterSpacing: 2, color: Colors.white54)),
      const SizedBox(height: 12),
      if (_transcript.isEmpty) const Text('Your adapter’s responses will appear here.', style: TextStyle(color: Colors.white38)),
      for (final entry in _transcript) Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: SelectableText(entry)),
    ],
  );
}
