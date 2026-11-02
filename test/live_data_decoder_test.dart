import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:crossscanmoto/diagnostics/live_data_definitions.dart';

void main() {
  final fixture =
      jsonDecode(
            File('test/fixtures/params_number_goldens.json').readAsStringSync(),
          )
          as Map<String, dynamic>;

  group('MotoScan NUMBER decoder source goldens', () {
    test(
      'requires the selected ECU to match the configured transport target',
      () {
        expect(BmwLiveDataDecoder.ecuMatches('ecu-a', 'ecu-a'), isTrue);
        expect(BmwLiveDataDecoder.ecuMatches('ecu-a', 'ecu-b'), isFalse);
        expect(BmwLiveDataDecoder.ecuMatches('ecu-a', null), isFalse);
      },
    );

    for (final item in fixture['cases'] as List) {
      final golden = item as Map<String, dynamic>;
      test(golden['name'] as String, () {
        final result = BmwLiveDataDecoder.decodeNumber(
          parameterRaw: golden['parameter_raw'] as String,
          resultRaw: golden['result_raw'] as String,
          udsData: (golden['uds_data'] as List).cast<int>(),
        );
        expect(result.isDecoded, isTrue);
        expect(result.raw, golden['expected_raw']);
        expect(result.value, closeTo(golden['expected_value'] as num, 1e-12));
      });
    }

    test('retains unresolved result types as raw', () {
      final result = BmwLiveDataDecoder.decodeNumber(
        parameterRaw: '1;22,62,00;VALUE;3;0;0;1;0',
        resultRaw: '10;1;VALUE;2;7;high;unsigned char;0;1;;1;1;1;0',
        udsData: [42],
      );
      expect(result.isDecoded, isFalse);
      expect(result.reason, 'Non-NUMBER result type');
    });

    test('retains truncated response without partial numeric output', () {
      final result = BmwLiveDataDecoder.decodeNumber(
        parameterRaw: '1;22,62,00;VALUE;3;0;0;1;0',
        resultRaw: '10;1;VALUE;1;7;high;unsigned int;0;2;;1;1;1;0',
        udsData: [0x12],
      );
      expect(result.isDecoded, isFalse);
      expect(result.reason, 'Response is too short for numeric definition');
    });

    test('does not divide by zero or decode unsupported C types', () {
      final zeroDivisor = BmwLiveDataDecoder.decodeNumber(
        parameterRaw: '1;22,62,00;VALUE;3;0;0;1;0',
        resultRaw: '10;1;VALUE;1;7;high;unsigned char;0;1;;1;1;0;0',
        udsData: [42],
      );
      final unsupported = BmwLiveDataDecoder.decodeNumber(
        parameterRaw: '1;22,62,00;VALUE;3;0;0;1;0',
        resultRaw: '10;1;VALUE;1;7;high;float;0;4;;1;1;1;0',
        udsData: [0, 0, 0, 0],
      );
      expect(zeroDivisor.isDecoded, isFalse);
      expect(unsupported.isDecoded, isFalse);
    });

    test('retains malformed scale, overflow, and mismatched parent rows', () {
      Map<String, dynamic> row(String raw, {String parent = '1'}) => {
        'parameter': '1;22,62,00;VALUE;3;0;0;1;0',
        'result': '10;$parent;VALUE;1;7;high;unsigned char;0;1;;1;$raw;1;0',
      };

      final malformed = row('not-a-number');
      final malformedResult = BmwLiveDataDecoder.decodeNumber(
        parameterRaw: malformed['parameter']!,
        resultRaw: malformed['result']!,
        udsData: [42],
      );
      final overflow = BmwLiveDataDecoder.decodeNumber(
        parameterRaw: '1;22,62,00;VALUE;3;0;0;1;0',
        resultRaw: '10;1;VALUE;1;7;high;unsigned char;0;1;;1;1e308;1e-300;0',
        udsData: [255],
      );
      final mismatch = row('1', parent: '2');
      final mismatchResult = BmwLiveDataDecoder.decodeNumber(
        parameterRaw: mismatch['parameter']!,
        resultRaw: mismatch['result']!,
        udsData: [42],
      );
      expect(malformedResult.isDecoded, isFalse);
      expect(overflow.isDecoded, isFalse);
      expect(mismatchResult.isDecoded, isFalse);
    });

    test('uses recovered nonstandard signed-char and C-type dispatch', () {
      BmwNumericResult decode(String cType, int length, List<int> bytes) =>
          BmwLiveDataDecoder.decodeNumber(
            parameterRaw: '1;22,62,00;VALUE;3;0;0;1;0',
            resultRaw: '10;1;VALUE;1;7;high;$cType;0;$length;;1;1;1;0',
            udsData: bytes,
          );

      expect(decode('signed char', 1, [0xff]).raw, 255);
      expect(decode('unsigned int', 2, [0xff, 0xff]).raw, 65535);
      expect(decode('int', 2, [0xff, 0xfe]).raw, -2);
      expect(decode('unsigned long', 4, [0x80, 0, 0, 0]).raw, -2147483648);
    });
  });
}
