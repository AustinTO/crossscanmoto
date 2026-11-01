import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:crossscanmoto/adapter_page.dart';

void main() {
  testWidgets('adapter port rejects values outside TCP port range',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 900));
    await tester
        .pumpWidget(const MaterialApp(home: Scaffold(body: AdapterPage())));

    await tester.enterText(find.byType(TextFormField).at(1), '65536');
    await tester.tap(find.text('Connect adapter'));
    await tester.pumpAndSettle();
    expect(find.text('Enter a port from 1 to 65535'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('adapter requires an address and accepts both port boundaries',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 900));
    await tester
        .pumpWidget(const MaterialApp(home: Scaffold(body: AdapterPage())));

    await tester.tap(find.text('Connect adapter'));
    await tester.pumpAndSettle();
    expect(find.text('Enter an address'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).at(1), '1');
    await tester.tap(find.text('Connect adapter'));
    await tester.pumpAndSettle();
    // The missing address still blocks connecting, while port 1 validates.
    expect(find.text('Enter a port from 1 to 65535'), findsNothing);
    expect(find.text('Enter an address'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).at(1), '65535');
    await tester.tap(find.text('Connect adapter'));
    await tester.pumpAndSettle();
    expect(find.text('Enter a port from 1 to 65535'), findsNothing);
    await tester.binding.setSurfaceSize(null);
  });
}
