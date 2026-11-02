import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:crossscanmoto/diagnostics/live_data_definitions.dart';

void main() {
  final fixture =
      jsonDecode(
            File('test/fixtures/params_result_layout_goldens.json')
                .readAsStringSync(),
          )
          as Map<String, dynamic>;

  group('MotoScan non-NUMBER result layout static goldens', () {
    final cases = fixture['cases'] as List;
    for (final item in cases) {
      final golden = item as Map<String, dynamic>;
      test(golden['name'] as String, () {
        final udsData = (golden['uds_data'] as List).cast<int>();
        final result = BmwLiveDataDecoder.decodeResult(
          parameterRaw: golden['parameter_raw'] as String,
          resultRaw: golden['result_raw'] as String,
          udsData: udsData,
          tabsRaw: (golden['tabs_raw'] as List).cast<String>(),
          tabTexts: (golden['tab_texts'] as Map).map(
            (key, value) => MapEntry(key.toString(), value.toString()),
          ),
          unit: golden['source_unit'] as String,
        );

        expect(result.format?.index, (golden['format'] as int) - 1);
        expect(result.rawBytes, (golden['expected_bytes'] as List).cast<int>());
        expect(result.rawValue, golden['expected_raw']);
        expect(result.displayUnit, golden['expected_unit']);
        if (golden['expected_decoded'] == true) {
          expect(result.isDecoded, isTrue);
          expect(result.displayValue, golden['expected']);
          expect(result.reason, isNull);
        } else {
          expect(result.isDecoded, isFalse);
          expect(result.displayValue, isNull);
          expect(result.reason, golden['reason']);
        }
      });
    }
  });
}
