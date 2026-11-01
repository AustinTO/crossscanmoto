import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:crossscanmoto/main.dart';

void main() {
  testWidgets('dashboard adapts at narrow and wide widths', (tester) async {
    for (final size in [const Size(360, 800), const Size(900, 900)]) {
      await tester.binding.setSurfaceSize(size);
      await tester.pumpWidget(const MotoDiagApp());
      expect(find.text('Your workshop,'), findsOneWidget);
      expect(find.text('Scan control units'), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('vehicle picker saves selected model and year', (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 850));
    await tester.pumpWidget(const MotoDiagApp());

    await tester.tap(find.text('Add your motorcycle'));
    await tester.pumpAndSettle();
    expect(find.text('Your motorcycle'), findsOneWidget);

    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('R 1250 GS').last);
    await tester.pumpAndSettle();

    await tester.tap(find.byType(DropdownButtonFormField<int>));
    await tester.pumpAndSettle();
    final year = DateTime.now().year - 1;
    await tester.tap(find.text('$year').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save vehicle'));
    await tester.pumpAndSettle();

    expect(find.text('R 1250 GS'), findsOneWidget);
    expect(find.text('Model year $year'), findsOneWidget);
    await tester.binding.setSurfaceSize(null);
  });
}
