import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:crossscanmoto/diagnostic_session.dart';
import 'package:crossscanmoto/diagnostics/elm_session.dart';
import 'package:crossscanmoto/diagnostics/uds_client.dart';
import 'package:crossscanmoto/live_data_page.dart';

void main() {
  final session = DiagnosticSession.instance;
  late _FakeTransport transport;
  late ElmSession elm;
  late _RecordingUdsLink link;

  setUp(() {
    transport = _FakeTransport();
    elm = ElmSession(transport);
    link = _RecordingUdsLink();
    session.attach(elm, identity: 'test adapter');
    session.attachUdsClient(UdsClient(link), ecuKey: 'cuX_BMSMP1');
  });

  tearDown(() async {
    session.detach();
    await elm.close();
  });

  testWidgets('does not query a catalog ECU other than the configured target', (
    tester,
  ) async {
    final catalog =
        jsonDecode(
              File(
                'assets/data/recovered_uds_parameters.json',
              ).readAsStringSync(),
            )
            as Map<String, dynamic>;
    final absRows = catalog['cuX_ABS'] as List;
    final parameterLabel = (absRows.first as Map)['label'] as String;

    await tester.pumpWidget(const MaterialApp(home: LiveDataPage()));
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    for (
      var i = 0;
      i < 20 && find.byType(DropdownButtonFormField<String>).evaluate().isEmpty;
      i++
    ) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    final ecuDropdown = tester
        .widgetList<DropdownButtonFormField<String>>(
          find.byType(DropdownButtonFormField<String>),
        )
        .first;
    ecuDropdown.onChanged!('cuX_ABS');
    await tester.pump();

    final parameterDropdown = tester.widget<DropdownButtonFormField<String>>(
      find.byType(DropdownButtonFormField<String>).last,
    );
    final selectedRow = absRows.first as Map;
    expect(selectedRow['label'], parameterLabel);
    parameterDropdown.onChanged!(selectedRow['id'] as String);
    await tester.pump();

    final readButton = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Read Live Value'),
    );
    readButton.onPressed!();
    await tester.pumpAndSettle();

    expect(link.requests, isEmpty);
    expect(find.textContaining('currently connected'), findsOneWidget);
  });
}

class _RecordingUdsLink implements UdsRequestLink {
  final requests = <List<int>>[];

  @override
  Future<List<int>> request(List<int> payload, {Duration? timeout}) async {
    requests.add(List.of(payload));
    return [0x62, payload[1], payload[2], 0];
  }
}

class _FakeTransport implements AdapterTransport {
  final _incoming = StreamController<List<int>>();

  @override
  Stream<List<int>> get incoming => _incoming.stream;

  @override
  Future<void> write(List<int> bytes) async {}

  @override
  Future<void> close() async => _incoming.close();
}
