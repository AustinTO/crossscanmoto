import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'diagnostic_session.dart';
import 'diagnostics/ecu_friendly_names.dart';
import 'diagnostics/live_data_definitions.dart';

const _lime = Color(0xFFBCEB58);
const _panel = Color(0xFF13181B);
const _muted = Color(0xFF929B9B);
const _edge = Color(0xFF293133);

/// Reads live sensor telemetry parameters from BMW Motorrad electronic control units.
class LiveDataPage extends StatefulWidget {
  const LiveDataPage({super.key});

  @override
  State<LiveDataPage> createState() => _LiveDataPageState();
}

class _LiveDataPageState extends State<LiveDataPage> {
  Map<String, dynamic>? _catalog;
  String? _ecu;
  Map<String, dynamic>? _parameter;
  String? _result;
  List<({String label, BmwLiveResult result})>? _decoded;
  int _readGeneration = 0;
  String? _error;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = jsonDecode(
        await rootBundle.loadString('assets/data/recovered_uds_parameters.json'),
      ) as Map<String, dynamic>;
      if (mounted) {
        setState(() {
          _catalog = data;
          final sessionKey = DiagnosticSession.instance.ecuDefinitionKey;
          if (sessionKey != null && data.containsKey(sessionKey)) {
            _ecu = sessionKey;
          } else if (data.containsKey('cuX_BMSMP1')) {
            _ecu = 'cuX_BMSMP1';
          } else if (data.isNotEmpty) {
            _ecu = data.keys.first;
          }
        });
      }
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    }
  }

  Future<void> _read() async {
    final parameter = _parameter;
    if (parameter == null) return;
    final sessionEcu = DiagnosticSession.instance.ecuDefinitionKey;
    if (!BmwLiveDataDecoder.ecuMatches(_ecu, sessionEcu)) {
      setState(() {
        _error = 'Select the control unit currently connected in the Adapter tab.';
        _result = null;
        _decoded = null;
      });
      return;
    }
    final generation = ++_readGeneration;
    setState(() {
      _busy = true;
      _error = null;
      _result = null;
      _decoded = null;
    });
    try {
      final bytes = await DiagnosticSession.instance.readDataIdentifier(
        parameter['did'] as int,
      );
      if (DiagnosticSession.instance.ecuDefinitionKey != sessionEcu ||
          generation != _readGeneration) {
        throw StateError('Connected control unit changed during the read.');
      }
      final decoded = <({String label, BmwLiveResult result})>[];
      for (final entry in (parameter['results'] as List? ?? const [])) {
        if (entry is! Map || entry['raw'] is! String) continue;
        final raw = entry['raw'] as String;
        final fields = raw.split(';');
        final tabRows = (entry['tabs'] as List? ?? const [])
            .whereType<Map>()
            .toList();
        final tabsRaw = tabRows
            .map((tab) => tab['raw'] as String?)
            .whereType<String>()
            .toList();
        final tabTexts = <String, String>{
          for (final tab in tabRows)
            if (tab['text_id'] != null && tab['text'] is String)
              tab['text_id'].toString(): tab['text'] as String,
        };
        if (tabsRaw.isEmpty) {
          tabsRaw.addAll(
            (entry['tabs_raw'] as List? ?? const []).cast<String>(),
          );
        }
        decoded.add((
          label: entry['label']?.toString() ??
              (fields.length > 2 ? fields[2] : 'Value'),
          result: BmwLiveDataDecoder.decodeResult(
            parameterRaw: parameter['raw'] as String,
            resultRaw: raw,
            udsData: bytes,
            tabsRaw: tabsRaw,
            tabTexts: tabTexts,
            unit: entry['unit']?.toString() ?? '',
          ),
        ));
      }
      if (mounted) {
        setState(() {
          _result = bytes
              .map((v) => v.toRadixString(16).padLeft(2, '0').toUpperCase())
              .join(' ');
          _decoded = decoded;
        });
      }
    } catch (error) {
      if (mounted && generation == _readGeneration) {
        setState(() => _error = error.toString());
      }
    } finally {
      if (mounted && generation == _readGeneration) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: const Color(0xFF080A0B),
        appBar: AppBar(
          backgroundColor: _panel,
          title: const Text('Live Telemetry & Sensors'),
        ),
        body: ListenableBuilder(
          listenable: DiagnosticSession.instance,
          builder: (context, _) => Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  Text(
                    'Real-Time Telemetry',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Select a control unit and sensor parameter to query real-time vehicle telemetry directly from your motorcycle.',
                    style: TextStyle(color: _muted),
                  ),
                  const SizedBox(height: 24),
                  if (_catalog == null && _error == null)
                    const LinearProgressIndicator(),
                  if (_catalog != null) ...[
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: _panel,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: _edge),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          DropdownButtonFormField<String>(
                            isExpanded: true,
                            initialValue: _ecu,
                            decoration: const InputDecoration(
                              labelText: 'Control Unit',
                              border: OutlineInputBorder(),
                            ),
                            items: [
                              for (final key in _catalog!.keys)
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
                                : (value) => setState(() {
                                          _readGeneration++;
                                      _ecu = value;
                                      _parameter = null;
                                      _result = null;
                                          _decoded = null;
                                    }),
                          ),
                          const SizedBox(height: 18),
                          if (_ecu != null)
                            DropdownButtonFormField<String>(
                              key: ValueKey(_ecu),
                              isExpanded: true,
                              initialValue: null,
                              decoration: const InputDecoration(
                                labelText: 'Sensor / Telemetry Parameter',
                                border: OutlineInputBorder(),
                              ),
                              items: [
                                for (final item in (_catalog![_ecu] as List))
                                  DropdownMenuItem(
                                    value: (item as Map)['id'] as String,
                                    child: Text(
                                      (item['label'] ?? item['name']) as String,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                              ],
                              onChanged: _busy
                                  ? null
                                  : (value) => setState(() {
                                        _readGeneration++;
                                        _parameter = Map<String, dynamic>.from(
                                          (_catalog![_ecu] as List).firstWhere(
                                            (item) => item['id'] == value,
                                          ) as Map,
                                        );
                                        _result = null;
                                        _decoded = null;
                                      }),
                            ),
                          const SizedBox(height: 18),
                          FilledButton.icon(
                            style: FilledButton.styleFrom(
                              backgroundColor: _lime,
                              foregroundColor: Colors.black,
                            ),
                            onPressed: _busy ||
                                    _parameter == null ||
                                    !DiagnosticSession.instance.protocolReady
                                ? null
                                : _read,
                            icon: const Icon(Icons.sensors),
                            label: Text(
                              _busy ? 'Reading Sensor…' : 'Read Live Value',
                            ),
                          ),
                          if (!DiagnosticSession.instance.protocolReady)
                            const Padding(
                              padding: EdgeInsets.only(top: 12),
                              child: Text(
                                'Connect your OBD adapter in the Adapter tab to query live telemetry.',
                                style: TextStyle(color: _muted, fontSize: 12),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                  if (_result != null) ...[
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: _panel,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: _lime.withValues(alpha: 0.5)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            (_parameter?['label'] ?? _parameter?['name'])
                                    ?.toString() ??
                                'Sensor Reading',
                            style: const TextStyle(
                              color: _lime,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 10),
                          SelectableText(
                            _result!.isEmpty ? 'ECU returned empty' : _result!,
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2,
                            ),
                          ),
                          if (_decoded != null && _decoded!.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            for (final item in _decoded!)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 6),
                                child: Text(
                                  '${item.label}: ${item.result.displayValue ?? 'Unresolved (${item.result.reason})'}${item.result.displayUnit.isEmpty ? '' : ' ${item.result.displayUnit}'}',
                                  style: const TextStyle(color: _muted),
                                ),
                              ),
                          ],
                        ],
                      ),
                    ),
                  ],
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 20),
                      child: Text(
                        _error!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      );
}
