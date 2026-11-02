import 'dart:convert';
import 'dart:io';

import 'package:crossscanmoto/diagnostics/live_data_definitions.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final root = Directory.current.path;
  final goldens =
      jsonDecode(
            File(
              '$root/test/fixtures/params_number_layout_goldens.json',
            ).readAsStringSync(),
          )
          as Map<String, dynamic>;
  final catalog =
      jsonDecode(
            File(
              '$root/assets/data/recovered_uds_parameters.json',
            ).readAsStringSync(),
          )
          as Map<String, dynamic>;

  test('decodes all source-derived NUMBER layout boundary vectors', () {
    final vectors = (goldens['cases'] as List).cast<Map<String, dynamic>>();
    final layouts = <String>{};
    final catalogLayouts = <String>{};
    final displayMismatches = <String>[];
    for (final entry in catalog.entries) {
      final parameters = (entry.value as List).cast<Map<String, dynamic>>();
      for (final parameter in parameters) {
        final results = (parameter['results'] as List)
            .cast<Map<String, dynamic>>();
        for (final result in results) {
          final fields = (result['raw'] as String).split(';');
          if (fields[3] == '1') {
            catalogLayouts.add(
              '${entry.key}\u0000${parameter['raw']}\u0000${result['raw']}',
            );
          }
        }
      }
    }

    for (final vector in vectors) {
      final ecu = vector['ecu_key'] as String;
      final parameterRaw = vector['parameter_raw'] as String;
      final resultRaw = vector['result_raw'] as String;
      final identity = '$ecu\u0000$parameterRaw\u0000$resultRaw';
      layouts.add(identity);
      final context =
          '$ecu / $parameterRaw / $resultRaw / ${vector['variant']}';
      final ecuParameters = (catalog[ecu] as List).cast<Map<String, dynamic>>();
      final parent = ecuParameters.where((row) => row['raw'] == parameterRaw);
      expect(parent, hasLength(1), reason: context);
      final results = (parent.single['results'] as List)
          .cast<Map<String, dynamic>>();
      expect(
        results.any((row) => row['raw'] == resultRaw),
        isTrue,
        reason: context,
      );

      final fullResponse = (vector['response_full'] as List).cast<int>();
      final parameterFields = parameterRaw.split(';');
      final did =
          int.parse(parameterFields[1].split(',')[1], radix: 16) * 256 +
          int.parse(parameterFields[1].split(',')[2], radix: 16);
      expect(fullResponse.take(3).toList(), [
        0x62,
        did >> 8,
        did & 0xff,
      ], reason: context);
      expect(vector['base_offset'], 3, reason: context);

      final decoded = BmwLiveDataDecoder.decodeNumber(
        parameterRaw: parameterRaw,
        resultRaw: resultRaw,
        // The UDS client clips SID and DID; the decoder rebases DEX offsets.
        udsData: fullResponse.sublist(3),
      );
      expect(decoded.isDecoded, isTrue, reason: '$context: ${decoded.reason}');
      expect(decoded.raw, vector['expected_raw'], reason: context);
      final expected = (vector['expected_value'] as num).toDouble();
      expect(
        decoded.value,
        closeTo(expected, expected.abs() * 1e-12 + 1e-12),
        reason: context,
      );
      final displayed = BmwLiveDataDecoder.decodeResult(
        parameterRaw: parameterRaw,
        resultRaw: resultRaw,
        udsData: fullResponse.sublist(3),
      );
      expect(
        displayed.isDecoded,
        isTrue,
        reason: '$context: ${displayed.reason}',
      );
      if (displayed.displayValue != vector['expected_display']) {
        displayMismatches.add(
          '$context: Java=${vector['expected_display']}, Dart=${displayed.displayValue}',
        );
      }
    }

    expect(catalogLayouts, hasLength(268));
    expect(layouts, catalogLayouts);
    expect(vectors, hasLength(804));
    expect(
      displayMismatches,
      isEmpty,
      reason:
          '${displayMismatches.length} Java/Dart display mismatch(es): '
          '${displayMismatches.take(8).join('\n')}',
    );
    expect(vectors.map((vector) => vector['variant']).toSet(), {
      'zero',
      'signed_boundary',
      'unsigned_max',
      'positive_max',
      'negative_min',
      'negative_one',
    });
  });
}
