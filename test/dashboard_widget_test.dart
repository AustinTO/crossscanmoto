import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:crossscanmoto/diagnostic_session.dart';
import 'package:crossscanmoto/diagnostics/elm_session.dart';
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

    await tester.tap(find.text('R 1250 GS'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Clear vehicle'));
    await tester.pumpAndSettle();
    expect(find.text('Add your motorcycle'), findsOneWidget);
    expect(find.text('MODEL YEAR NOT SET'), findsOneWidget);
    expect(DiagnosticSession.instance.profile.modelName, isNull);
    expect(DiagnosticSession.instance.profile.modelYear, isNull);
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('garage mirrors shared vehicle and adapter state', (
    tester,
  ) async {
    final shared = DiagnosticSession.instance;
    shared.clearVehicleProfile();
    shared.updateVehicleProfile(
      model: 'F 850 GS',
      year: 2022,
      autoIdentified: true,
    );
    final transport = _DashboardTestTransport();
    final elm = ElmSession(transport);
    shared.attach(elm, identity: 'Test adapter', voltage: '12.4 V');
    addTearDown(() async {
      shared.detach();
      await tester.runAsync(() => elm.close());
      shared.clearVehicleProfile();
      await tester.binding.setSurfaceSize(null);
    });

    await tester.binding.setSurfaceSize(const Size(390, 844));
    await tester.pumpWidget(const MotoDiagApp());
    await tester.pumpAndSettle();

    expect(find.text('F 850 GS'), findsOneWidget);
    expect(find.text('Model year 2022'), findsOneWidget);
    expect(find.text('CONNECTED'), findsOneWidget);
    expect(find.text('Test adapter'), findsOneWidget);

    shared.detach();
    await tester.pump();
    expect(find.text('NO ADAPTER'), findsOneWidget);
  });
}

class _DashboardTestTransport implements AdapterTransport {
  final _incoming = StreamController<List<int>>();

  @override
  Stream<List<int>> get incoming => _incoming.stream;

  @override
  Future<void> write(List<int> bytes) async {}

  @override
  Future<void> close() => _incoming.close();
}
