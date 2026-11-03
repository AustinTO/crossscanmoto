import 'dart:convert';
import 'dart:io';

import 'package:crossscanmoto/diagnostics/bmw_coding_engine.dart';
import 'package:crossscanmoto/diagnostics/uds_client.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeUdsLink implements UdsRequestLink {
  _FakeUdsLink({this.onSend});

  final Future<List<int>> Function(List<int> request)? onSend;
  final List<List<int>> recordedRequests = [];

  @override
  Future<List<int>> request(List<int> payload, {Duration? timeout}) async {
    recordedRequests.add(payload);
    if (onSend != null) {
      return onSend!(payload);
    }
    return [payload.first + 0x40, ...payload.skip(1)];
  }
}

void main() {
  late BmwCodingDefinitionCatalog catalog;

  setUpAll(() {
    final file = File('assets/data/recovered_coding_definitions.json');
    final map = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    catalog = BmwCodingDefinitionCatalog.fromJson(map);
  });

  group('BmwCodingDefinitionCatalog', () {
    test('loads all variants with expected totals', () {
      expect(catalog.totalVariants, greaterThanOrEqualTo(45));
      expect(catalog.totalParameters, greaterThanOrEqualTo(3000));
      expect(catalog.totalOptions, greaterThanOrEqualTo(8000));
    });

    test('matches variants with normalizations', () {
      final kombi = catalog.matchVariant('KOMBI_K25', 0x04);
      expect(kombi, isNotNull);
      expect(kombi!.key, 'KMBI_K25_C04');

      final zfe = catalog.matchVariant('ZFE', '08');
      expect(zfe, isNotNull);
      expect(zfe!.key, 'ZFE_C08');

      final mrzfe = catalog.matchVariant('MRZFE', 0x08);
      expect(mrzfe, isNotNull);
      expect(mrzfe!.key, 'ZFE_C08');

      final bmsk = catalog.matchVariant('BMSK', 0);
      expect(bmsk, isNotNull);
      expect(bmsk!.key, 'BMSK_C00');

      final unknown = catalog.matchVariant('UNKNOWN_ECU', 99);
      expect(unknown, isNull);
    });
  });

  group('Parameter Decoding and Encoding', () {
    test('decodes CLOCK_MODE and ODO_UNIT correctly from Country_Code block', () {
      final kombi = catalog.matchVariant('KMBI_K25', '04')!;
      final clockParam = kombi.findParameter('CLOCK_MODE')!;
      final odoParam = kombi.findParameter('ODO_UNIT')!;

      // Country_Code DID 0x3005: length 3
      // Offset 1:
      // bit 0: CLOCK_MODE (01 = 24h, 00 = 12h)
      // bit 2: ODO_UNIT (00 = km, 04 = mls)

      // Test 1: 24h and km (byte at offset 1 = 0x01)
      final blockPayload1 = [0x00, 0x01, 0x00];
      expect(clockParam.decodeValue(blockPayload1), '24h');
      expect(odoParam.decodeValue(blockPayload1), 'km');

      // Test 2: 12h and mls (byte at offset 1 = 0x04)
      final blockPayload2 = [0x00, 0x04, 0x00];
      expect(clockParam.decodeValue(blockPayload2), '12h');
      expect(odoParam.decodeValue(blockPayload2), 'mls');

      // Test 3: 24h and mls (byte at offset 1 = 0x05)
      final blockPayload3 = [0x00, 0x05, 0x00];
      expect(clockParam.decodeValue(blockPayload3), '24h');
      expect(odoParam.decodeValue(blockPayload3), 'mls');
    });

    test('encodes parameter preserving unmasked bits', () {
      final kombi = catalog.matchVariant('KMBI_K25', '04')!;
      final clockParam = kombi.findParameter('CLOCK_MODE')!;
      final odoParam = kombi.findParameter('ODO_UNIT')!;

      // Initial: byte 1 = 0x05 (24h + mls)
      var block = [0x00, 0x05, 0x00];

      // Change clock to 12h (clears bit 0, preserves mls bit 2)
      block = clockParam.encodeValue(block, '12h');
      expect(block[1], 0x04);
      expect(clockParam.decodeValue(block), '12h');
      expect(odoParam.decodeValue(block), 'mls');

      // Change odo to km (clears bit 2, preserves 12h)
      block = odoParam.encodeValue(block, 'km');
      expect(block[1], 0x00);
      expect(clockParam.decodeValue(block), '12h');
      expect(odoParam.decodeValue(block), 'km');

      // Change clock back to 24h (sets bit 0, preserves km)
      block = clockParam.encodeValue(block, '24h');
      expect(block[1], 0x01);
      expect(clockParam.decodeValue(block), '24h');
      expect(odoParam.decodeValue(block), 'km');
    });
  });

  group('BmwCodingEngine Safety & Backups', () {
    test('creates tamper-evident verified backup with hash', () {
      final engine = BmwCodingEngine(catalog: catalog);
      final kombi = catalog.matchVariant('KMBI_K25', '04')!;

      final rawBlocks = <int, List<int>>{
        0x3005: [0x00, 0x01, 0x00],
        0x300A: [0x00, 0x00, 0x00, 0x00, 0x00],
        0x300B: List.filled(13, 0),
        0x300F: List.filled(9, 0),
      };

      final backup = engine.createBackup(
        vin: 'WB103820987654321',
        vehicleModel: 'R1200GS',
        variant: kombi,
        blockPayloads: rawBlocks,
      );

      expect(backup.vin, 'WB103820987654321');
      expect(backup.vehicleModel, 'R1200GS');
      expect(backup.variantKey, 'KMBI_K25_C04');
      expect(backup.sha256Hash, isNotEmpty);
      expect(backup.decodedParameters['CLOCK_MODE'], '24h');

      final jsonMap = backup.toJson();
      final restored = VerifiedCodingBackup.fromJson(jsonMap);
      expect(restored.id, backup.id);
      expect(restored.sha256Hash, backup.sha256Hash);
      expect(restored.decodedParameters['CLOCK_MODE'], '24h');
    });

    test('fail-closed write safety: writing is rejected when allowPhysicalWrites is false', () async {
      final engine = BmwCodingEngine(catalog: catalog, allowPhysicalWrites: false);
      final kombi = catalog.matchVariant('KMBI_K25', '04')!;
      final link = _FakeUdsLink();
      final client = UdsClient(link);

      final orig = <int, List<int>>{0x3005: [0x00, 0x01, 0x00]};
      final modified = <int, List<int>>{0x3005: [0x00, 0x00, 0x00]};

      expect(
        () => engine.writeCodingBlocks(
          client: client,
          variant: kombi,
          originalBlocks: orig,
          updatedBlocks: modified,
        ),
        throwsA(isA<BmwCodingSafetyException>()),
      );
      expect(link.recordedRequests, isEmpty);
    });

    test('executes write, reset, and readback verification when allowPhysicalWrites is true', () async {
      final engine = BmwCodingEngine(catalog: catalog, allowPhysicalWrites: true);
      final kombi = catalog.matchVariant('KMBI_K25', '04')!;

      final storedState = <int, List<int>>{
        0x3005: [0x00, 0x01, 0x00],
      };

      final link = _FakeUdsLink(onSend: (req) async {
        final sid = req.first;
        if (sid == 0x2E) {
          // WriteDataByIdentifier: [0x2E, DID_h, DID_l, ...data]
          final did = (req[1] << 8) | req[2];
          storedState[did] = req.skip(3).toList();
          return [0x6E, req[1], req[2]];
        } else if (sid == 0x11) {
          // ECUReset: [0x11, subfunc]
          return [0x51, req[1]];
        } else if (sid == 0x22) {
          // ReadDataByIdentifier: [0x22, DID_h, DID_l]
          final did = (req[1] << 8) | req[2];
          return [0x62, req[1], req[2], ...storedState[did]!];
        }
        return [sid + 0x40];
      });

      final client = UdsClient(link);

      final orig = <int, List<int>>{0x3005: [0x00, 0x01, 0x00]};
      final modified = <int, List<int>>{0x3005: [0x00, 0x00, 0x00]};

      await engine.writeCodingBlocks(
        client: client,
        variant: kombi,
        originalBlocks: orig,
        updatedBlocks: modified,
      );

      // Verify request sequence: Write (0x2E) -> Reset (0x11) -> Readback (0x22)
      expect(link.recordedRequests.length, 3);
      expect(link.recordedRequests[0].first, 0x2E);
      expect(link.recordedRequests[1].first, 0x11);
      expect(link.recordedRequests[2].first, 0x22);
    });
  });
}
