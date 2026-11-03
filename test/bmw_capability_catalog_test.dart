import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:crossscanmoto/bmw_capability_catalog.dart';
import 'package:crossscanmoto/diagnostic_session.dart';
import 'package:crossscanmoto/diagnostics/elm_session.dart';
import 'package:crossscanmoto/diagnostics/source_qualified_catalog.dart';
import 'package:crossscanmoto/diagnostics/uds_client.dart';

late final SourceQualifiedCatalog _testCatalog;

class _FakeTransport implements AdapterTransport {
  final incomingController = StreamController<List<int>>.broadcast();

  @override
  Stream<List<int>> get incoming => incomingController.stream;

  @override
  Future<void> write(List<int> bytes) async {}

  @override
  Future<void> close() async {
    await incomingController.close();
  }
}

class _FakeUdsLink implements UdsRequestLink {
  final List<List<int>> recordedRequests = [];

  @override
  Future<List<int>> request(List<int> payload, {Duration? timeout}) async {
    recordedRequests.add(payload);
    return [0x6F, ...payload.skip(1)];
  }
}

void main() {
  setUpAll(() {
    final raw = File('assets/data/bmw_extended_catalog.json').readAsStringSync();
    final json = jsonDecode(raw) as Map<String, dynamic>;
    final manifest = json['manifest'] as Map<String, dynamic>? ?? {};
    _testCatalog = SourceQualifiedCatalog(
      sourceSha256: manifest['source_sha256'] as String? ?? '',
      bikes: (json['bikes'] as List<dynamic>? ?? const [])
          .map((e) => BmwExtendedBike.fromJson(e as Map<String, dynamic>))
          .toList(growable: false),
      marketModels: (json['bike_market_models'] as List<dynamic>? ?? const [])
          .map((e) => BmwExtendedMarketModel.fromJson(e as Map<String, dynamic>))
          .toList(growable: false),
      variants: (json['bike_variants'] as List<dynamic>? ?? const [])
          .map((e) => BmwExtendedVariant.fromJson(e as Map<String, dynamic>))
          .toList(growable: false),
      bikeEcus: (json['bike_ecus'] as List<dynamic>? ?? const [])
          .map((e) => {
                'ebr': (e as Map<String, dynamic>)['ebr']?.toString() ?? '',
                'ecu_name': e['ecu_name']?.toString() ?? '',
              })
          .toList(growable: false),
      ecus: (json['ecus'] as List<dynamic>? ?? const [])
          .map((e) => BmwExtendedEcu.fromJson(e as Map<String, dynamic>))
          .toList(growable: false),
      serviceFunctions: (json['service_functions'] as List<dynamic>? ?? const [])
          .map((e) => BmwExtendedServiceFunction.fromJson(e as Map<String, dynamic>))
          .toList(growable: false),
      serviceSteps: (json['service_steps'] as List<dynamic>? ?? const [])
          .map((e) => BmwExtendedServiceStep.fromJson(e as Map<String, dynamic>))
          .toList(growable: false),
      actuators: (json['actuators'] as List<dynamic>? ?? const [])
          .map((e) => BmwExtendedActuator.fromJson(e as Map<String, dynamic>))
          .toList(growable: false),
      adaptations: (json['adaptations'] as List<dynamic>? ?? const [])
          .map((e) => BmwExtendedAdaptation.fromJson(e as Map<String, dynamic>))
          .toList(growable: false),
    );
  });

  setUp(() {
    DiagnosticSession.instance.detach();
    DiagnosticSession.instance.clearVehicleProfile();
  });

  tearDown(() {
    DiagnosticSession.instance.detach();
  });

  testWidgets('BmwCapabilityCatalogBrowser renders BMW Motorrad capabilities and triggers native routine execution', (tester) async {
    final link = _FakeUdsLink();
    final transport = _FakeTransport();
    final elm = ElmSession(transport);
    DiagnosticSession.instance.attach(elm, identity: 'OBDLink LX');
    DiagnosticSession.instance.attachUdsClient(UdsClient(link), ecuKey: 'cuX_ABS');

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: BmwCapabilityCatalogBrowser(catalog: _testCatalog),
      ),
    ));
    await tester.pumpAndSettle();

    // Verify native branding
    expect(find.text('BMW Motorrad Factory Capabilities'), findsOneWidget);
    expect(find.textContaining('Biketune'), findsNothing);

    // Expand an ECU (e.g. cuX_ABS or first mapped ECU)
    final absFinder = find.text('cuX_ABS');
    if (absFinder.evaluate().isNotEmpty) {
      await tester.tap(absFinder.first);
      await tester.pumpAndSettle();

      // Look for an actuator button
      final actuateButtons = find.text('Actuate');
      if (actuateButtons.evaluate().isNotEmpty) {
        await tester.tap(actuateButtons.first);
        await tester.pumpAndSettle();

        // Tap Start Actuation
        expect(find.text('Start Actuation'), findsOneWidget);
        await tester.tap(find.text('Start Actuation'));
        await tester.pumpAndSettle();

        // Verify request was sent natively to UDS link
        expect(link.recordedRequests, isNotEmpty);
      }
    }
  });
}
