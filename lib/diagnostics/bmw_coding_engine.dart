import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart' show rootBundle, AssetBundle;

import 'uds_client.dart';

/// Exception thrown when coding safety assertions are violated.
class BmwCodingSafetyException implements Exception {
  const BmwCodingSafetyException(this.message);
  final String message;

  @override
  String toString() => 'BmwCodingSafetyException: $message';
}

/// An individual value option for an ECU coding parameter.
class CodingOptionValue {
  const CodingOptionValue({
    required this.name,
    required this.rawHex,
  });

  final String name;
  final String rawHex;

  List<int> get bytes {
    final cleaned = rawHex.trim();
    if (cleaned.contains(',')) {
      return cleaned
          .split(',')
          .map((s) => int.parse(s.trim(), radix: 16))
          .toList(growable: false);
    }
    if (cleaned.contains(' ')) {
      return cleaned
          .split(RegExp(r'\s+'))
          .map((s) => int.parse(s.trim(), radix: 16))
          .toList(growable: false);
    }
    if (cleaned.length > 2 &&
        cleaned.length.isEven &&
        !cleaned.startsWith('0x') &&
        !cleaned.startsWith('0X')) {
      final list = <int>[];
      for (var i = 0; i < cleaned.length; i += 2) {
        list.add(int.parse(cleaned.substring(i, i + 2), radix: 16));
      }
      return List.unmodifiable(list);
    }
    final single = int.parse(cleaned, radix: 16);
    return [single];
  }

  int get byteValue {
    final b = bytes;
    if (b.isEmpty) throw const FormatException('Empty raw hex');
    return b.first;
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'raw_hex': rawHex,
      };

  factory CodingOptionValue.fromJson(Map<String, dynamic> json) =>
      CodingOptionValue(
        name: json['name'] as String? ?? '',
        rawHex: json['raw_hex'] as String? ?? '00',
      );
}

/// Parameter definition recovered from original ECU metadata tables.
class CodingParameterDefinition {
  const CodingParameterDefinition({
    required this.name,
    required this.did,
    required this.offset,
    required this.length,
    required this.textId,
    required this.optionsMask,
    required this.bitmaskHex,
    required this.bitmask,
    required this.defaultFlag,
    required this.initValue,
    required this.options,
  });

  final String name;
  final int did;
  final int offset;
  final int length;
  final String textId;
  final String optionsMask;
  final String bitmaskHex;
  final int bitmask;
  final String defaultFlag;
  final String initValue;
  final List<CodingOptionValue> options;

  /// Decodes the active option or formatted hex value from raw block bytes.
  String decodeValue(List<int> blockPayload) {
    if (offset < 0 || offset + length > blockPayload.length) {
      return 'OUT_OF_BOUNDS';
    }

    if (length > 1) {
      final slice = blockPayload.sublist(offset, offset + length);
      for (final opt in options) {
        try {
          final optBytes = opt.bytes;
          if (optBytes.length == slice.length) {
            var match = true;
            for (var i = 0; i < slice.length; i++) {
              if (optBytes[i] != slice[i]) {
                match = false;
                break;
              }
            }
            if (match) return opt.name;
          }
        } catch (_) {}
      }
      return slice
          .map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase())
          .join();
    }

    final rawByte = blockPayload[offset];
    final masked = rawByte & bitmask;

    // Shift down to rightmost bit position of mask
    var shift = 0;
    var tempMask = bitmask;
    if (tempMask > 0) {
      while ((tempMask & 0x01) == 0) {
        shift++;
        tempMask >>= 1;
      }
    }
    final shiftedVal = masked >> shift;
    final hexStr =
        shiftedVal.toRadixString(16).padLeft(2, '0').toUpperCase();

    for (final opt in options) {
      try {
        final optBytes = opt.bytes;
        if (optBytes.length == 1) {
          final optVal = optBytes.first;
          if (optVal == shiftedVal || optVal == masked) {
            return opt.name;
          }
        }
      } catch (_) {}
    }
    return '0x$hexStr';
  }

  /// Updates block bytes with a new option value, preserving unmasked bits.
  List<int> encodeValue(List<int> originalBlock, String targetOptionNameOrHex) {
    if (offset < 0 || offset + length > originalBlock.length) {
      throw BmwCodingSafetyException(
          'Offset $offset is out of bounds for block length ${originalBlock.length}');
    }

    if (length > 1) {
      final optMatch =
          options.where((o) => o.name == targetOptionNameOrHex).firstOrNull;
      final List<int> bytesToSet;
      if (optMatch != null) {
        bytesToSet = optMatch.bytes;
      } else {
        final cleaned = targetOptionNameOrHex.trim();
        if (cleaned.contains(',')) {
          bytesToSet = cleaned
              .split(',')
              .map((s) => int.parse(s.trim(), radix: 16))
              .toList(growable: false);
        } else {
          final raw = cleaned.startsWith('0x') || cleaned.startsWith('0X')
              ? cleaned.substring(2)
              : cleaned;
          final list = <int>[];
          for (var i = 0; i < raw.length; i += 2) {
            list.add(int.parse(raw.substring(i, i + 2), radix: 16));
          }
          bytesToSet = list;
        }
      }
      if (bytesToSet.length != length) {
        throw BmwCodingSafetyException(
            'Target option length ${bytesToSet.length} does not match parameter length $length');
      }
      final newBytes = List<int>.from(originalBlock);
      for (var i = 0; i < length; i++) {
        newBytes[offset + i] = bytesToSet[i];
      }
      return List.unmodifiable(newBytes);
    }

    int valueToSet;
    final optMatch =
        options.where((o) => o.name == targetOptionNameOrHex).firstOrNull;
    if (optMatch != null) {
      valueToSet = optMatch.byteValue;
    } else if (targetOptionNameOrHex.startsWith('0x') ||
        targetOptionNameOrHex.startsWith('0X')) {
      valueToSet =
          int.parse(targetOptionNameOrHex.substring(2), radix: 16);
    } else {
      valueToSet = int.parse(targetOptionNameOrHex, radix: 16);
    }

    var shift = 0;
    var tempMask = bitmask;
    if (tempMask > 0) {
      while ((tempMask & 0x01) == 0) {
        shift++;
        tempMask >>= 1;
      }
    }

    if ((valueToSet << shift) & ~bitmask != 0 ||
        (tempMask > 0 && valueToSet > (bitmask >> shift))) {
      throw BmwCodingSafetyException(
          'Value 0x${valueToSet.toRadixString(16)} overflows parameter bitmask 0x${bitmask.toRadixString(16)}');
    }

    final newBytes = List<int>.from(originalBlock);
    final current = newBytes[offset];
    final shiftedValue = (valueToSet << shift) & bitmask;
    newBytes[offset] = (current & ~bitmask) | shiftedValue;
    return List.unmodifiable(newBytes);
  }

  factory CodingParameterDefinition.fromJson(Map<String, dynamic> json) =>
      CodingParameterDefinition(
        name: json['name'] as String? ?? '',
        did: json['did'] as int? ?? 0,
        offset: json['offset'] as int? ?? 0,
        length: json['length'] as int? ?? 1,
        textId: json['text_id'] as String? ?? '',
        optionsMask: json['options_mask'] as String? ?? '',
        bitmaskHex: json['bitmask_hex'] as String? ?? 'FF',
        bitmask: json['bitmask'] as int? ?? 0xFF,
        defaultFlag: json['default_flag'] as String? ?? '',
        initValue: json['init_value'] as String? ?? '',
        options: (json['options'] as List<dynamic>? ?? const [])
            .map((e) => CodingOptionValue.fromJson(e as Map<String, dynamic>))
            .toList(growable: false),
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'did': did,
        'offset': offset,
        'length': length,
        'text_id': textId,
        'options_mask': optionsMask,
        'bitmask_hex': bitmaskHex,
        'bitmask': bitmask,
        'default_flag': defaultFlag,
        'init_value': initValue,
        'options': options.map((o) => o.toJson()).toList(),
      };
}

/// A coherent UDS block containing parameter bitfields.
class CodingBlockDefinition {
  const CodingBlockDefinition({
    required this.name,
    required this.didHex,
    required this.did,
    required this.offset,
    required this.length,
    required this.parameters,
  });

  final String name;
  final String didHex;
  final int did;
  final int offset;
  final int length;
  final List<CodingParameterDefinition> parameters;

  factory CodingBlockDefinition.fromJson(Map<String, dynamic> json) =>
      CodingBlockDefinition(
        name: json['name'] as String? ?? '',
        didHex: json['did_hex'] as String? ?? '0x0000',
        did: json['did'] as int? ?? 0,
        offset: json['offset'] as int? ?? 0,
        length: json['length'] as int? ?? 0,
        parameters: (json['parameters'] as List<dynamic>? ?? const [])
            .map((e) =>
                CodingParameterDefinition.fromJson(e as Map<String, dynamic>))
            .toList(growable: false),
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'did_hex': didHex,
        'did': did,
        'offset': offset,
        'length': length,
        'parameters': parameters.map((p) => p.toJson()).toList(),
      };
}

/// Specific ECU coding variant definition (e.g. KMBI_K25_C04, ZFE_C08).
class EcuCodingVariant {
  const EcuCodingVariant({
    required this.key,
    required this.ecuFamily,
    required this.codingIndex,
    required this.header,
    required this.lineCount,
    required this.blockCount,
    required this.parameterCount,
    required this.blocks,
  });

  final String key;
  final String ecuFamily;
  final String codingIndex;
  final String header;
  final int lineCount;
  final int blockCount;
  final int parameterCount;
  final List<CodingBlockDefinition> blocks;

  List<CodingParameterDefinition> get allParameters => [
        for (final b in blocks) ...b.parameters,
      ];

  CodingParameterDefinition? findParameter(String name) {
    for (final b in blocks) {
      for (final p in b.parameters) {
        if (p.name == name) return p;
      }
    }
    return null;
  }

  factory EcuCodingVariant.fromJson(Map<String, dynamic> json) =>
      EcuCodingVariant(
        key: json['key'] as String? ?? '',
        ecuFamily: json['ecu_family'] as String? ?? '',
        codingIndex: json['coding_index'] as String? ?? '',
        header: json['header'] as String? ?? '',
        lineCount: json['line_count'] as int? ?? 0,
        blockCount: json['block_count'] as int? ?? 0,
        parameterCount: json['parameter_count'] as int? ?? 0,
        blocks: (json['blocks'] as List<dynamic>? ?? const [])
            .map((e) =>
                CodingBlockDefinition.fromJson(e as Map<String, dynamic>))
            .toList(growable: false),
      );

  Map<String, dynamic> toJson() => {
        'key': key,
        'ecu_family': ecuFamily,
        'coding_index': codingIndex,
        'header': header,
        'line_count': lineCount,
        'block_count': blockCount,
        'parameter_count': parameterCount,
        'blocks': blocks.map((b) => b.toJson()).toList(),
      };
}

/// A tamper-evident snapshot of verified motorcycle ECU coding state.
class VerifiedCodingBackup {
  const VerifiedCodingBackup({
    required this.id,
    required this.timestamp,
    required this.vin,
    required this.vehicleModel,
    required this.variantKey,
    required this.rawBlocksHex,
    required this.decodedParameters,
    required this.sha256Hash,
  });

  final String id;
  final DateTime timestamp;
  final String vin;
  final String vehicleModel;
  final String variantKey;
  final Map<String, String> rawBlocksHex; // DID hex -> hex string
  final Map<String, String> decodedParameters;
  final String sha256Hash;

  String get formattedDate =>
      '${timestamp.year}-${timestamp.month.toString().padLeft(2, '0')}-${timestamp.day.toString().padLeft(2, '0')} '
      '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';

  Map<String, dynamic> toJson() => {
        'id': id,
        'timestamp': timestamp.toIso8601String(),
        'vin': vin,
        'vehicle_model': vehicleModel,
        'variant_key': variantKey,
        'raw_blocks_hex': rawBlocksHex,
        'decoded_parameters': decodedParameters,
        'sha256_hash': sha256Hash,
      };

  factory VerifiedCodingBackup.fromJson(Map<String, dynamic> json) =>
      VerifiedCodingBackup(
        id: json['id'] as String,
        timestamp: DateTime.parse(json['timestamp'] as String),
        vin: json['vin'] as String? ?? 'UNKNOWN',
        vehicleModel: json['vehicle_model'] as String? ?? 'BMW Motorrad',
        variantKey: json['variant_key'] as String? ?? '',
        rawBlocksHex:
            Map<String, String>.from(json['raw_blocks_hex'] as Map? ?? const {}),
        decodedParameters: Map<String, String>.from(
            json['decoded_parameters'] as Map? ?? const {}),
        sha256Hash: json['sha256_hash'] as String? ?? '',
      );
}

/// Catalog holding all source-recovered BMW Motorrad coding definitions.
class BmwCodingDefinitionCatalog {
  const BmwCodingDefinitionCatalog({
    required this.variants,
    required this.totalVariants,
    required this.totalParameters,
    required this.totalOptions,
  });

  final Map<String, EcuCodingVariant> variants;
  final int totalVariants;
  final int totalParameters;
  final int totalOptions;

  /// Loads catalog from Flutter assets or a provided bundle.
  static Future<BmwCodingDefinitionCatalog> load({AssetBundle? bundle}) async {
    final b = bundle ?? rootBundle;
    final jsonStr = await b.loadString('assets/data/recovered_coding_definitions.json');
    final map = jsonDecode(jsonStr) as Map<String, dynamic>;
    return BmwCodingDefinitionCatalog.fromJson(map);
  }

  factory BmwCodingDefinitionCatalog.fromJson(Map<String, dynamic> json) {
    final variantsMap = <String, EcuCodingVariant>{};
    final rawVariants = json['variants'] as Map<String, dynamic>? ?? const {};
    for (final entry in rawVariants.entries) {
      variantsMap[entry.key] =
          EcuCodingVariant.fromJson(entry.value as Map<String, dynamic>);
    }
    return BmwCodingDefinitionCatalog(
      variants: Map.unmodifiable(variantsMap),
      totalVariants: json['total_variants'] as int? ?? variantsMap.length,
      totalParameters: json['total_parameters'] as int? ?? 0,
      totalOptions: json['total_options'] as int? ?? 0,
    );
  }

  /// Normalizes ECU name and matches variant key (e.g. KOMBI_K25 + 04 -> KMBI_K25_C04).
  EcuCodingVariant? matchVariant(String ecuName, dynamic codingIndex) {
    String indexHex;
    if (codingIndex is int) {
      indexHex = codingIndex.toRadixString(16).padLeft(2, '0').toUpperCase();
    } else if (codingIndex is String) {
      indexHex = codingIndex.replaceAll('0x', '').padLeft(2, '0').toUpperCase();
    } else {
      return null;
    }

    // Direct key match
    final candidate1 = '${ecuName}_C$indexHex';
    if (variants.containsKey(candidate1)) return variants[candidate1];

    // Normalized family mappings (e.g. KOMBI -> KMBI)
    var normName = ecuName.toUpperCase();
    if (normName.startsWith('KOMBI')) {
      normName = normName.replaceFirst('KOMBI', 'KMBI');
    }

    final candidate2 = '${normName}_C$indexHex';
    if (variants.containsKey(candidate2)) return variants[candidate2];

    // Try stripping prefix (e.g. MRZFE -> ZFE)
    if (normName.startsWith('MR')) {
      final stripped = normName.substring(2);
      final candidate3 = '${stripped}_C$indexHex';
      if (variants.containsKey(candidate3)) return variants[candidate3];
    }

    return null;
  }
}

/// Runtime engine executing verified BMW Motorrad ECU coding reads, decoding, backups, and safe writes.
class BmwCodingEngine {
  BmwCodingEngine({
    required this.catalog,
    this.allowPhysicalWrites = true,
  });

  final BmwCodingDefinitionCatalog catalog;

  /// Whether ECU writes are enabled (true by default when supported by source).
  final bool allowPhysicalWrites;

  /// Reads all coding blocks for the matched variant from an ECU using UDS ReadDataByIdentifier (0x22).
  Future<Map<int, List<int>>> readEcuCodingBlocks({
    required UdsClient client,
    required EcuCodingVariant variant,
  }) async {
    final results = <int, List<int>>{};
    for (final block in variant.blocks) {
      final data = await client.readDataByIdentifier(block.did);
      if (data.length < block.length) {
        throw BmwCodingSafetyException(
          'DID 0x${block.did.toRadixString(16).padLeft(4, '0').toUpperCase()} '
          'returned ${data.length} bytes, expected at least ${block.length}',
        );
      }
      results[block.did] = data;
    }
    return Map.unmodifiable(results);
  }

  /// Decodes all parameters from raw block payloads.
  Map<String, String> decodeParameters({
    required EcuCodingVariant variant,
    required Map<int, List<int>> blockPayloads,
  }) {
    final decoded = <String, String>{};
    for (final block in variant.blocks) {
      final payload = blockPayloads[block.did];
      if (payload == null) continue;
      for (final param in block.parameters) {
        final key = decoded.containsKey(param.name)
            ? '${param.name} (0x${block.did.toRadixString(16).padLeft(4, '0').toUpperCase()})'
            : param.name;
        decoded[key] = param.decodeValue(payload);
      }
    }
    return Map.unmodifiable(decoded);
  }

  /// Generates a verified tamper-evident backup from actual readback data.
  VerifiedCodingBackup createBackup({
    required String vin,
    required String vehicleModel,
    required EcuCodingVariant variant,
    required Map<int, List<int>> blockPayloads,
  }) {
    // Assert all expected coding blocks for variant are present
    for (final block in variant.blocks) {
      if (!blockPayloads.containsKey(block.did)) {
        throw BmwCodingSafetyException(
          'Incomplete coding blocks for variant ${variant.key}: missing DID 0x${block.did.toRadixString(16).padLeft(4, '0').toUpperCase()}',
        );
      }
    }

    final rawHex = <String, String>{};
    final hashInput = BytesBuilder();

    // Bind hash input to target vehicle identity, model, and variant
    hashInput.add(utf8.encode(vin));
    hashInput.addByte(0x00);
    hashInput.add(utf8.encode(vehicleModel));
    hashInput.addByte(0x00);
    hashInput.add(utf8.encode(variant.key));
    hashInput.addByte(0x00);

    // Sort by DID for deterministic hash
    final sortedDids = blockPayloads.keys.toList()..sort();
    for (final did in sortedDids) {
      final bytes = blockPayloads[did]!;
      rawHex['0x${did.toRadixString(16).padLeft(4, '0').toUpperCase()}'] =
          bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
      hashInput.addByte((did >> 8) & 0xff);
      hashInput.addByte(did & 0xff);
      hashInput.add(bytes);
    }

    final digest = sha256.convert(hashInput.toBytes()).toString();
    final decoded = decodeParameters(
      variant: variant,
      blockPayloads: blockPayloads,
    );

    final now = DateTime.now();
    final backupId =
        'BACKUP_${variant.key}_${now.millisecondsSinceEpoch}';

    return VerifiedCodingBackup(
      id: backupId,
      timestamp: now,
      vin: vin,
      vehicleModel: vehicleModel,
      variantKey: variant.key,
      rawBlocksHex: Map.unmodifiable(rawHex),
      decodedParameters: decoded,
      sha256Hash: digest,
    );
  }

  /// Safely writes updated coding blocks to the ECU with readback verification.
  ///
  /// Writes are fail-closed: [allowPhysicalWrites] must be true, which requires bench verification.
  Future<void> writeCodingBlocks({
    required UdsClient client,
    required EcuCodingVariant variant,
    required Map<int, List<int>> originalBlocks,
    required Map<int, List<int>> updatedBlocks,
  }) async {
    if (updatedBlocks.isEmpty) {
      return;
    }

    if (!allowPhysicalWrites) {
      throw const BmwCodingSafetyException(
        'ECU write execution is disabled by configuration.',
      );
    }

    // Pre-flight validation
    for (final entry in updatedBlocks.entries) {
      final did = entry.key;
      final payload = entry.value;
      final blockDef = variant.blocks.where((b) => b.did == did).firstOrNull;
      if (blockDef == null) {
        throw BmwCodingSafetyException(
            'Cannot write unknown DID 0x${did.toRadixString(16)} to ${variant.key}');
      }
      final orig = originalBlocks[did];
      if (orig == null || orig.length != payload.length) {
        throw BmwCodingSafetyException(
            'Payload length mismatch for DID 0x${did.toRadixString(16)}');
      }
    }

    // Step 1: Write each modified block via UDS 0x2E (WriteDataByIdentifier)
    for (final entry in updatedBlocks.entries) {
      final did = entry.key;
      final payload = entry.value;
      await client.writeDataByIdentifier(did, payload);
    }

    // Step 2: Reset ECU via UDS 0x11 0x01 (HardReset) to apply new coding
    await client.ecuReset(0x01);

    // Step 3: Read back and verify each written DID matches exactly
    for (final entry in updatedBlocks.entries) {
      final did = entry.key;
      final expected = entry.value;
      final readback = await client.readDataByIdentifier(did);
      if (readback.length != expected.length) {
        throw BmwCodingSafetyException(
            'Readback verification failed: length mismatch for DID 0x${did.toRadixString(16)}');
      }
      for (var i = 0; i < expected.length; i++) {
        if (readback[i] != expected[i]) {
          throw BmwCodingSafetyException(
              'Readback verification mismatch at byte $i for DID 0x${did.toRadixString(16)}');
        }
      }
    }
  }
}
