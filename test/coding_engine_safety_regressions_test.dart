// Candidate RED tests for CrossScanMoto HEAD 6f074fb.
// Copy into the repository test/ directory and run with flutter test.
// These tests have NOT been executed in this handoff environment.
// ALL requests use a synthetic fake UDS link. No physical ECU access.
import 'package:flutter_test/flutter_test.dart';
import 'package:crossscanmoto/diagnostics/bmw_coding_engine.dart';
import 'package:crossscanmoto/diagnostics/uds_client.dart';

class _FakeLink implements UdsRequestLink {
  final requests = <List<int>>[];
  @override
  Future<List<int>> request(List<int> payload, {Duration? timeout}) async {
    requests.add(List<int>.from(payload));
    if (payload.first == 0x11) return [0x51, payload[1]];
    if (payload.first == 0x2E) return [0x6E, payload[1], payload[2]];
    if (payload.first == 0x22) return [0x62, payload[1], payload[2], 0x01];
    return [payload.first + 0x40];
  }
}

CodingParameterDefinition _param({
  String name = 'P', int did = 0x3001, int offset = 0,
  int length = 1, int bitmask = 0xff, List<CodingOptionValue> options = const [],
}) => CodingParameterDefinition(
  name: name, did: did, offset: offset, length: length,
  textId: '', optionsMask: '', bitmaskHex: bitmask.toRadixString(16),
  bitmask: bitmask, defaultFlag: '', initValue: '', options: options,
);

EcuCodingVariant _variant(List<CodingBlockDefinition> blocks) => EcuCodingVariant(
  key: 'TEST_C01', ecuFamily: 'TEST', codingIndex: '01', header: 'TEST.C01',
  lineCount: 0, blockCount: blocks.length,
  parameterCount: blocks.fold(0, (sum, b) => sum + b.parameters.length),
  blocks: blocks,
);

CodingBlockDefinition _block(int did, int length, List<CodingParameterDefinition> fields) =>
  CodingBlockDefinition(name: 'B$did', didHex: '0x${did.toRadixString(16)}',
    did: did, offset: 0, length: length, parameters: fields);

void main() {
  final cat = BmwCodingDefinitionCatalog(
    variants: const {}, totalVariants: 0, totalParameters: 0, totalOptions: 0,
  );

  test('invalid option hex must fail, not silently become 0', () {
    const option = CodingOptionValue(name: 'bad', rawHex: 'ZZ');
    expect(() => option.byteValue, throwsFormatException);
  });

  test('multi-byte option must compare complete payload, not only first byte', () {
    final p = _param(length: 2, options: const [
      CodingOptionValue(name: 'pair', rawHex: '12,34'),
    ]);
    expect(p.decodeValue([0x12, 0x34]), 'pair');
  });

  test('duplicate parameter labels in separate DIDs must not overwrite', () {
    final v = _variant([
      _block(0x3001, 1, [_param(name: 'same', did: 0x3001)]),
      _block(0x3002, 1, [_param(name: 'same', did: 0x3002)]),
    ]);
    final values = BmwCodingEngine(catalog: cat).decodeParameters(
      variant: v, blockPayloads: {0x3001: [0x01], 0x3002: [0x02]},
    );
    expect(values.length, 2);
  });

  test('incomplete expected coding blocks cannot become a complete backup', () {
    final v = _variant([
      _block(0x3001, 1, [_param(did: 0x3001)]),
      _block(0x3002, 1, [_param(did: 0x3002)]),
    ]);
    final engine = BmwCodingEngine(catalog: cat);
    expect(() => engine.createBackup(
      vin: 'TESTVIN0000000001', vehicleModel: 'Synthetic test', variant: v,
      blockPayloads: {0x3001: [0x01]},
    ), throwsA(isA<BmwCodingSafetyException>()));
  });

  test('backup fingerprint is bound to target identity and variant', () {
    final v = _variant([_block(0x3001, 1, [_param()])]);
    final engine = BmwCodingEngine(catalog: cat);
    final a = engine.createBackup(vin: 'TESTVIN0000000001',
      vehicleModel: 'Synthetic test', variant: v, blockPayloads: {0x3001: [0x01]});
    final b = engine.createBackup(vin: 'TESTVIN0000000002',
      vehicleModel: 'Synthetic test', variant: v, blockPayloads: {0x3001: [0x01]});
    expect(a.sha256Hash, isNot(b.sha256Hash));
  });

  test('zero changed blocks never send ECUReset, even in fake-enabled mode', () async {
    final link = _FakeLink();
    final client = UdsClient(link);
    final engine = BmwCodingEngine(catalog: cat, allowPhysicalWrites: true);
    await engine.writeCodingBlocks(client: client, variant: _variant([]),
      originalBlocks: const {}, updatedBlocks: const {});
    expect(link.requests, isEmpty);
  });

  test('field overflow cannot be silently masked into a different value', () {
    final p = _param(bitmask: 0x03);
    expect(() => p.encodeValue([0x00], '0xFF'),
      throwsA(isA<BmwCodingSafetyException>()));
  });

  test('DID responses shorter than source block length must fail', () async {
    final v = _variant([_block(0x3001, 3, [_param()])]);
    final link = _FakeLink(); // returns one data byte for 0x22
    final engine = BmwCodingEngine(catalog: cat);
    expect(() => engine.readEcuCodingBlocks(
      client: UdsClient(link), variant: v,
    ), throwsA(anyOf(isA<BmwCodingSafetyException>(), isA<FormatException>())));
  });
}
