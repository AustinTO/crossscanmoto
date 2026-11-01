import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:crossscanmoto/preferences_page.dart';

void main() {
  testWidgets('PreferencesPage pumps and renders text', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: PreferencesPage(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Preferences & Legal'), findsOneWidget);
    expect(find.text('WORKSHOP & DISPLAY'), findsOneWidget);
    expect(find.text('CLOUD ACCOUNT & SYNC'), findsOneWidget);
    expect(find.text('About CrossScan Moto'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Delete Account & Stored Data'), 200);
    expect(find.text('Delete Account & Stored Data'), findsOneWidget);
  });
}
