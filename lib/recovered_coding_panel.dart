import 'package:flutter/material.dart';

import 'diagnostic_session.dart';
import 'diagnostics/bmw_coding_engine.dart';

const _lime = Color(0xFFBCEB58);
const _panel = Color(0xFF14191B);
const _ink = Color(0xFF0A0D0E);
const _muted = Color(0xFF929B9B);

/// Interactive ECU Coding inspection, parameter decoding, and backup panel.
class RecoveredCodingPanel extends StatefulWidget {
  const RecoveredCodingPanel({super.key});

  @override
  State<RecoveredCodingPanel> createState() => _RecoveredCodingPanelState();
}

class _RecoveredCodingPanelState extends State<RecoveredCodingPanel> {
  BmwCodingDefinitionCatalog? _catalog;
  String? _selectedVariantKey;
  bool _loadingCatalog = true;
  bool _readingEcu = false;
  String? _statusMessage;
  Map<int, List<int>> _rawBlocks = {};
  Map<String, String> _decodedValues = {};
  final List<VerifiedCodingBackup> _savedBackups = [];

  @override
  void initState() {
    super.initState();
    _loadCatalog();
  }

  Future<void> _loadCatalog() async {
    try {
      final cat = await BmwCodingDefinitionCatalog.load();
      if (!mounted) return;
      setState(() {
        _catalog = cat;
        _loadingCatalog = false;
        // Default to KMBI_K25_C04 or first variant
        if (cat.variants.isNotEmpty) {
          _selectedVariantKey = cat.variants.containsKey('KMBI_K25_C04')
              ? 'KMBI_K25_C04'
              : cat.variants.keys.first;
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingCatalog = false;
        _statusMessage = 'Failed to load coding catalog: $e';
      });
    }
  }

  Future<void> _readFromEcu() async {
    final session = DiagnosticSession.instance;
    final cat = _catalog;
    final variantKey = _selectedVariantKey;
    if (cat == null || variantKey == null) return;
    final variant = cat.variants[variantKey];
    if (variant == null) return;

    if (!session.connected) {
      setState(() {
        _statusMessage =
            'No active motorcycle diagnostic session. Connect an OBD adapter to read live coding blocks.';
      });
      return;
    }

    setState(() {
      _readingEcu = true;
      _statusMessage = 'Reading ${variant.blocks.length} coding blocks via UDS ReadDataByIdentifier (0x22)...';
    });

    try {
      final client = session.udsClient;
      if (client == null) {
        throw Exception('No active UDS client communication link.');
      }
      final engine = BmwCodingEngine(catalog: cat);

      final blocks = await engine.readEcuCodingBlocks(
        client: client,
        variant: variant,
      );

      final decoded = engine.decodeParameters(
        variant: variant,
        blockPayloads: blocks,
      );

      // This snapshot is held in memory only.
      final autoBackup = engine.createBackup(
        vin: session.profile.vin ?? 'UNKNOWN',
        vehicleModel: session.profile.modelName ?? 'BMW Motorrad',
        variant: variant,
        blockPayloads: blocks,
      );

      if (!mounted) return;
      setState(() {
        _rawBlocks = blocks;
        _decodedValues = decoded;
        _readingEcu = false;
        _savedBackups.insert(0, autoBackup);
        _statusMessage =
            'Read ${blocks.length} blocks (${decoded.length} parameters decoded). Snapshot is in memory only and will be lost when this screen closes.';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _readingEcu = false;
        _statusMessage = 'Read failed: $e';
      });
    }
  }

  void _createBackup() {
    final cat = _catalog;
    final variantKey = _selectedVariantKey;
    if (cat == null || variantKey == null) return;
    final variant = cat.variants[variantKey];
    if (variant == null) return;

    if (_rawBlocks.isEmpty) {
      setState(() {
        _statusMessage = 'No coding blocks have been read yet. Read ECU coding first.';
      });
      return;
    }

    final engine = BmwCodingEngine(catalog: cat);
    final backup = engine.createBackup(
      vin: DiagnosticSession.instance.profile.vin ?? 'UNKNOWN',
      vehicleModel:
          DiagnosticSession.instance.profile.modelName ?? 'BMW Motorrad',
      variant: variant,
      blockPayloads: _rawBlocks,
    );

    setState(() {
      _savedBackups.insert(0, backup);
      _statusMessage =
          'Snapshot created in memory only. It will be lost when this screen closes.';
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingCatalog) {
      return const Center(
        child: CircularProgressIndicator(color: _lime),
      );
    }

    final cat = _catalog;
    if (cat == null) {
      return Center(
        child: Text(
          _statusMessage ?? 'Coding catalog unavailable',
          style: const TextStyle(color: Colors.white70),
        ),
      );
    }

    final variant = _selectedVariantKey != null ? cat.variants[_selectedVariantKey] : null;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Safety Guardrail Alert Banner
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF1F1A12),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE5A93C).withValues(alpha: 0.5)),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.shield_outlined, color: Color(0xFFE5A93C), size: 20),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hardware Safety Guardrail Active',
                      style: TextStyle(
                        color: Color(0xFFE5A93C),
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'ECU coding writes are disabled pending physical bench validation. Coding snapshots are held in memory only and cannot be restored to the ECU.',
                      style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.35),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Variant Selector Card
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
                    'ECU Coding Variant',
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
                      '${cat.totalVariants} Variants',
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
                initialValue: _selectedVariantKey,
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
                items: cat.variants.keys.map((k) {
                  final v = cat.variants[k]!;
                  return DropdownMenuItem<String>(
                    value: k,
                    child: Text('${v.key} (${v.header} · ${v.parameterCount} params)'),
                  );
                }).toList(),
                onChanged: (newKey) {
                  setState(() {
                    _selectedVariantKey = newKey;
                    _rawBlocks.clear();
                    _decodedValues.clear();
                    _statusMessage = null;
                  });
                },
              ),
              if (variant != null) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    _metaChip('Family', variant.ecuFamily),
                    const SizedBox(width: 8),
                    _metaChip('Index', 'C${variant.codingIndex}'),
                    const SizedBox(width: 8),
                    _metaChip('Blocks', '${variant.blockCount}'),
                    const SizedBox(width: 8),
                    _metaChip('Params', '${variant.parameterCount}'),
                  ],
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Action Buttons Row
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: _lime,
                  foregroundColor: _ink,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: _readingEcu ? null : _readFromEcu,
                icon: _readingEcu
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: _ink),
                      )
                    : const Icon(Icons.download, size: 18),
                label: Text(
                  _readingEcu ? 'Reading...' : 'Read ECU Coding',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white24),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: _rawBlocks.isNotEmpty ? _createBackup : null,
                icon: const Icon(Icons.save_alt, size: 18),
                label: const Text(
                  'Create Temporary Snapshot',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            ),
          ],
        ),

        if (_statusMessage != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF18261B),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _lime.withValues(alpha: 0.3)),
            ),
            child: Text(
              _statusMessage!,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ),
        ],

        const SizedBox(height: 18),

        // Parameters Section
        if (variant != null) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Parameters (${variant.parameterCount})',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              if (_decodedValues.isNotEmpty)
                Text(
                  '${_decodedValues.length} active values decoded',
                  style: const TextStyle(color: _lime, fontSize: 11),
                ),
            ],
          ),
          const SizedBox(height: 10),
          for (final block in variant.blocks) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: _panel,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white10),
              ),
              child: Theme(
                data: ThemeData.dark().copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  initiallyExpanded: true,
                  title: Text(
                    '${block.name} (DID ${block.didHex})',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    'Offset: ${block.offset} · Length: ${block.length} bytes · ${block.parameters.length} parameters',
                    style: const TextStyle(color: _muted, fontSize: 11),
                  ),
                  children: [
                    const Divider(height: 1, color: Colors.white10),
                    for (final param in block.parameters)
                      _buildParameterTile(param),
                  ],
                ),
              ),
            ),
          ],
        ],

        // Verified Backups Section
        if (_savedBackups.isNotEmpty) ...[
          const SizedBox(height: 16),
          const Text(
            'Temporary Snapshots',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 10),
          for (final b in _savedBackups)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _panel,
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
                        b.id,
                        style: const TextStyle(
                          color: _lime,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        b.formattedDate,
                        style: const TextStyle(color: _muted, fontSize: 11),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'VIN: ${b.vin} · Model: ${b.vehicleModel} · Variant: ${b.variantKey}',
                    style: const TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'SHA-256: ${b.sha256Hash}',
                    style: const TextStyle(
                      color: _muted,
                      fontSize: 10,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),
        ],
      ],
    );
  }

  Widget _buildParameterTile(CodingParameterDefinition param) {
    final activeVal = _decodedValues[param.name];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.white10, width: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  param.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 12.5,
                  ),
                ),
              ),
              if (activeVal != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: _lime.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: _lime.withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    activeVal,
                    style: const TextStyle(
                      color: _lime,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                'Byte ${param.offset} · Mask 0x${param.bitmaskHex}',
                style: const TextStyle(color: _muted, fontSize: 10.5),
              ),
              if (param.options.isNotEmpty) ...[
                const SizedBox(width: 8),
                Text(
                  'Options: ${param.options.map((o) => o.name).join(', ')}',
                  style: const TextStyle(color: Colors.white54, fontSize: 10.5),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _metaChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _ink,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.white12),
      ),
      child: Text(
        '$label: $value',
        style: const TextStyle(color: Colors.white70, fontSize: 11),
      ),
    );
  }
}
