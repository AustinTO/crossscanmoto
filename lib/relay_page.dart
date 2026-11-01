import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'diagnostic_session.dart';
import 'diagnostics/adapter_profile.dart';
import 'diagnostics/adapter_relay.dart';
import 'diagnostics/bluetooth_transport.dart';
import 'diagnostics/elm_session.dart';
import 'diagnostics/relay_connect.dart';

/// Android hosts a paired Classic adapter; iOS connects to that host over LAN.
class RelayPage extends StatefulWidget {
  const RelayPage({super.key});

  @override
  State<RelayPage> createState() => _RelayPageState();
}

class _RelayPageState extends State<RelayPage> {
  final _hostController = TextEditingController();
  final _portController = TextEditingController(text: '');
  final _tokenController = TextEditingController();
  PairedBluetoothDevice? _device;
  AdapterRelayServer? _server;
  StreamSubscription<AdapterRelayState>? _serverSubscription;
  bool _busy = false;
  String? _error;
  String? _notice;
  ElmSession? _relaySession;

  bool get _isAndroid => Theme.of(context).platform == TargetPlatform.android;

  @override
  void dispose() {
    _serverSubscription?.cancel();
    final server = _server;
    if (server != null) unawaited(server.stop());
    _hostController.dispose();
    _portController.dispose();
    _tokenController.dispose();
    super.dispose();
  }

  Future<void> _selectDevice() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final devices = await BluetoothAdapterTransport.pairedDevices();
      if (!mounted) return;
      final selection = await showModalBottomSheet<PairedBluetoothDevice>(
        context: context,
        showDragHandle: true,
        builder: (context) => SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              const ListTile(
                title: Text('Paired Bluetooth adapters'),
                subtitle:
                    Text('Pair the LX in Android Bluetooth settings first.'),
              ),
              if (devices.isEmpty)
                const ListTile(title: Text('No paired devices found')),
              for (final device in devices)
                ListTile(
                  leading: const Icon(Icons.bluetooth),
                  title: Text(device.name),
                  subtitle: Text(device.address),
                  onTap: () => Navigator.pop(context, device),
                ),
            ],
          ),
        ),
      );
      if (selection != null && mounted) {
        setState(() => _device = selection);
      }
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _startRelay() async {
    if (_device == null) {
      setState(() => _error = 'Select a paired Bluetooth adapter first.');
      return;
    }
    if (DiagnosticSession.instance.connected) {
      setState(() => _error =
          'Disconnect the active adapter in the Connect screen before hosting.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
      _notice = null;
    });
    try {
      final selectedDevice = _device!;
      final server = await AdapterRelayServer.start(
        diagnosticSessionConnected: DiagnosticSession.instance.connected,
        connectBluetooth: () =>
            BluetoothAdapterTransport.connect(selectedDevice),
      );
      _serverSubscription?.cancel();
      _serverSubscription = server.stateChanges.listen((state) {
        if (!mounted) return;
        setState(() {
          if (state == AdapterRelayState.connected) {
            _notice = 'iPhone authenticated and connected.';
          } else if (state == AdapterRelayState.listening) {
            _notice = 'Waiting for the iPhone to authenticate.';
          } else if (state == AdapterRelayState.stopped &&
              identical(_server, server)) {
            _server = null;
            _notice = 'Relay stopped. The adapter connection was closed.';
          }
        });
      });
      if (!mounted) {
        await server.stop();
        return;
      }
      setState(() {
        _server = server;
        _notice = 'Relay is listening on this local network.';
      });
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _stopRelay() async {
    final server = _server;
    _server = null;
    await _serverSubscription?.cancel();
    _serverSubscription = null;
    await server?.stop();
    if (mounted) {
      setState(() => _notice = 'Relay stopped and Bluetooth disconnected.');
    }
  }

  Future<void> _copyToken() async {
    final token = _server?.info.token;
    if (token == null) return;
    await Clipboard.setData(ClipboardData(text: token));
    if (mounted) setState(() => _notice = 'Relay token copied.');
  }

  Future<void> _connectRelay() async {
    if (DiagnosticSession.instance.connected) {
      setState(() => _error =
          'Disconnect the active adapter in the Connect screen first.');
      return;
    }
    final host = _hostController.text.trim();
    final port = int.tryParse(_portController.text.trim());
    if (host.isEmpty || port == null || port < 1 || port > 65535) {
      setState(() => _error = 'Enter the Android host address and valid port.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
      _notice = null;
    });
    ElmSession? candidate;
    try {
      final transport = await RelayAdapterTransport.connect(
        host,
        port,
        _tokenController.text.trim(),
      );
      candidate = ElmSession(transport);
      final initialized = await initializeAdapter(candidate);
      if (!mounted) {
        await candidate.close();
        return;
      }
      final profile = initialized.profile;
      DiagnosticSession.instance.attach(
        candidate,
        identity: profile.ati.text.isEmpty ? null : profile.ati.text,
        voltage:
            initialized.voltage.isError || initialized.voltage.lines.isEmpty
                ? null
                : initialized.voltage.text,
      );
      _relaySession = candidate;
      setState(() => _notice = 'Connected to the Android adapter relay.');
    } catch (error) {
      await candidate?.close();
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _disconnectRelay() async {
    final session = _relaySession;
    _relaySession = null;
    if (identical(DiagnosticSession.instance.elmSession, session)) {
      DiagnosticSession.instance.detach();
    }
    await session?.close();
    if (mounted) setState(() => _notice = 'Relay client disconnected.');
  }

  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text('Adapter relay',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          const Text(
            'Use an Android phone as the Bluetooth bridge for an iPhone on the same local network.',
            style: TextStyle(color: Colors.white60),
          ),
          const SizedBox(height: 24),
          if (_isAndroid) _buildHostCard() else _buildClientCard(),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Text(_error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ),
          if (_notice != null)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child:
                  Text(_notice!, style: const TextStyle(color: Colors.white70)),
            ),
        ],
      );

  Widget _buildHostCard() {
    final server = _server;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Android bridge host',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          const Text(
            'Disconnect any active adapter session first. The relay owns the selected adapter until it stops or the iPhone disconnects. The token and adapter traffic are unencrypted; use this only on a trusted local network.',
            style: TextStyle(color: Colors.white60),
          ),
          const SizedBox(height: 16),
          if (server == null) ...[
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(_device?.name ?? 'No adapter selected'),
              subtitle: Text(_device?.address ?? 'Choose a paired LX adapter'),
              trailing: OutlinedButton(
                onPressed: _busy ? null : _selectDevice,
                child: const Text('Select'),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _busy ? null : _startRelay,
                icon: const Icon(Icons.wifi_tethering),
                label: Text(_busy ? 'Starting…' : 'Start relay'),
              ),
            ),
          ] else ...[
            const Text('Host address', style: TextStyle(color: Colors.white54)),
            for (final address in server.info.addresses)
              SelectableText('$address:${server.info.port}'),
            const SizedBox(height: 12),
            const Text('One-time relay token',
                style: TextStyle(color: Colors.white54)),
            SelectableText(server.info.token,
                style: const TextStyle(fontFamily: 'monospace')),
            const SizedBox(height: 8),
            Wrap(spacing: 12, children: [
              OutlinedButton.icon(
                onPressed: _copyToken,
                icon: const Icon(Icons.copy),
                label: const Text('Copy token'),
              ),
              FilledButton.tonalIcon(
                onPressed: _busy ? null : _stopRelay,
                icon: const Icon(Icons.stop_circle_outlined),
                label: const Text('Stop relay'),
              ),
            ]),
          ],
        ]),
      ),
    );
  }

  Widget _buildClientCard() {
    final connected = _relaySession != null;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Connect to Android host',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          const Text(
              'Enter the host address, port, and token shown on Android.',
              style: TextStyle(color: Colors.white60)),
          const SizedBox(height: 16),
          TextField(
            controller: _hostController,
            enabled: !_busy && !connected,
            decoration: const InputDecoration(
                labelText: 'Android host address',
                border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _portController,
            enabled: !_busy && !connected,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
                labelText: 'Port', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _tokenController,
            enabled: !_busy && !connected,
            obscureText: true,
            autocorrect: false,
            enableSuggestions: false,
            decoration: const InputDecoration(
                labelText: 'Relay token', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _busy
                  ? null
                  : connected
                      ? _disconnectRelay
                      : _connectRelay,
              icon: Icon(connected ? Icons.link_off : Icons.link),
              label: Text(_busy
                  ? 'Connecting…'
                  : connected
                      ? 'Disconnect relay'
                      : 'Connect'),
            ),
          ),
        ]),
      ),
    );
  }
}
