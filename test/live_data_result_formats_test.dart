import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:crossscanmoto/diagnostics/live_data_definitions.dart';

void main() {
  final fixture =
      jsonDecode(
            File(
              'test/fixtures/params_result_formats_goldens.json',
            ).readAsStringSync(),
          )
          as Map<String, dynamic>;

  group('MotoScan PARAMS_RES result format source goldens', () {
    for (final item in fixture['cases'] as List) {
      final golden = item as Map<String, dynamic>;
      test(golden['name'] as String, () {
        final result = BmwLiveDataDecoder.decodeResult(
          parameterRaw: golden['parameter_raw'] as String,
          resultRaw: golden['result_raw'] as String,
          udsData: (golden['uds_data'] as List).cast<int>(),
          tabsRaw: (golden['tabs_raw'] as List? ?? const []).cast<String>(),
          tabTexts: (golden['tab_texts'] as Map? ?? const {}).map(
            (key, value) => MapEntry(key.toString(), value.toString()),
          ),
          tabGlobalRaw: (golden['tab_global_raw'] as List? ?? const [])
              .cast<String>(),
          tabGlobalKeyHeader: golden['tab_global_key_header'] as String?,
          tabGlobalValueHeader: golden['tab_global_value_header'] as String?,
          unit: golden['unit'] as String? ?? '',
          decimalSeparator: golden['decimal_separator'] as String? ?? '.',
          zeroDigit: golden['zero_digit'] as String? ?? '0',
        );
        if (golden['expected_unresolved'] == true) {
          expect(result.isDecoded, isFalse);
          expect(result.reason, golden['reason']);
        } else {
          expect(result.isDecoded, isTrue);
          expect(result.displayValue, golden['expected']);
        }
        expect(result.displayUnit, golden['expected_unit'] ?? '');
        expect(result.isPlaceholder, golden['expected_placeholder'] ?? false);
        expect(result.format?.index, (golden['format'] as int) - 1);
        expect(result.rawValue, golden['expected_raw']);
        expect(result.rawBytes, (golden['uds_data'] as List).cast<int>());
      });
    }

    test('preserves extracted bytes when source row is invalid', () {
      final result = BmwLiveDataDecoder.decodeResult(
        parameterRaw: '1;22,62,00;VALUE;3;0;0;1;0',
        resultRaw: '10;2;VALUE;5;7;high;data;0;2;;0;1;1;0',
        udsData: [0x12, 0x34],
      );
      expect(result.isDecoded, isFalse);
      expect(result.rawBytes, [0x12, 0x34]);
      expect(result.reason, 'Result does not match its parent parameter');
    });

    test('retains bytes for truncated results and rejects invalid bounds', () {
      final result = BmwLiveDataDecoder.decodeResult(
        parameterRaw: '1;22,62,00;VALUE;3;0;0;1;0',
        resultRaw: '10;1;VALUE;5;7;high;data;1;3;;0;1;1;0',
        udsData: [0x12, 0x34],
      );
      expect(result.isDecoded, isFalse);
      expect(result.rawBytes, isEmpty);
      expect(result.reason, 'Response is too short for result definition');
    });

    test('retains bytes when trailing metadata is incomplete', () {
      final result = BmwLiveDataDecoder.decodeResult(
        parameterRaw: '1;22,62,00;VALUE;3;0;0;1;0',
        resultRaw: '10;1;VALUE;5;7;high;data;0;2;;0;1;1',
        udsData: [0x12, 0x34],
      );
      expect(result.isDecoded, isFalse);
      expect(result.rawBytes, [0x12, 0x34]);
      expect(result.reason, 'Incomplete source row');
    });
  });
}
