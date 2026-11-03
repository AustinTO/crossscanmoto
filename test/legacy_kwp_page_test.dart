import 'dart:async';
import 'dart:collection';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:crossscanmoto/diagnostic_session.dart';
import 'package:crossscanmoto/diagnostics/elm_session.dart';
import 'package:crossscanmoto/diagnostics/uds_client.dart';
import 'package:crossscanmoto/legacy_kwp_page.dart';

class _KwpTransport implements AdapterTransport {
  final incomingController = StreamController<List<int>>();
  final writes = <String>[];
  final replies = <String, Queue<Future<String>>>{};
  bool closed = false;
  bool? protocolReadyAtFirstAtCommand;
  bool Function()? protocolReady;

  void reply(String command, String value) {
    replies.putIfAbsent(command, Queue.new).add(Future.value(value));
  }

  void replyFuture(String command, Future<String> value) {
    replies.putIfAbsent(command, Queue.new).add(value);
  }

  @override
  Stream<List<int>> get incoming => incomingController.stream;

  @override
  Future<void> write(List<int> bytes) async {
    final command = ascii.decode(bytes).replaceFirst('\r', '');
    writes.add(command);
    if (command.startsWith('AT') && protocolReadyAtFirstAtCommand == null) {
      protocolReadyAtFirstAtCommand = protocolReady?.call();
    }

    final scripted = replies[command];
    final response = scripted != null && scripted.isNotEmpty
        ? await scripted.removeFirst()
        : _defaultResponse(command);
    incomingController.add(ascii.encode('$response\r>'));
  }

  String _defaultResponse(String command) {
    if (command.startsWith('AT')) return 'OK';
    if (command.startsWith('3B') && command.length >= 4) {
      return _frame([0x7b, int.parse(command.substring(2, 4), radix: 16)]);
    }
    return switch (command) {
      '81' => _frame([0xc1]),
      '1A80' => _frame([0x5a, 0x80, 0x12]),
      '1802FFFF' => _frame([0x58, 0x00]),
      '14FFFF' => _frame([0x54]),
      _ => _frame([0x57, 0x00]),
    };
  }

  static String _frame(List<int> payload) => [
    payload.length,
    ...payload,
    0,
  ].map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();

  @override
  Future<void> close() async {
    closed = true;
    await incomingController.close();
  }
}

class _UnusedUdsLink implements UdsRequestLink {
  @override
  Future<List<int>> request(List<int> payload, {Duration? timeout}) async =>
      const [0x59, 0x02, 0xff];
}

class _Harness {
  final shared = DiagnosticSession.instance;
  final sessions = <ElmSession>[];

  ElmSession attach(_KwpTransport transport, {String? identity}) {
    transport.protocolReady = () => shared.protocolReady;
    final session = ElmSession(transport);
    sessions.add(session);
    shared.attach(session, identity: identity);
    return session;
  }

  Future<void> cleanup(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    shared.detach();
    for (final session in sessions) {
      await session.close();
    }
  }
}

Future<void> _configure(WidgetTester tester) async {
  await tester.enterText(find.byKey(const ValueKey('kwp-ecu-address')), '12');
  await tester.tap(find.byKey(const ValueKey('kwp-configure')));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('KWP setup clears shared UDS readiness before adapter AT setup', (
    tester,
  ) async {
    final harness = _Harness();
    final transport = _KwpTransport();
    final session = harness.attach(transport, identity: 'test adapter');
    harness.shared.attachUdsClient(
      UdsClient(_UnusedUdsLink()),
      forGeneration: harness.shared.generation,
    );
    addTearDown(() => harness.cleanup(tester));

    await tester.pumpWidget(const MaterialApp(home: LegacyKwpPage()));
    expect(harness.shared.protocolReady, isTrue);
    await _configure(tester);

    expect(transport.protocolReadyAtFirstAtCommand, isFalse);
    expect(harness.shared.protocolReady, isFalse);
    expect(find.text('Configured for ECU 12'), findsOneWidget);
    expect(identical(harness.shared.elmSession, session), isTrue);
  });

  testWidgets('KWP setup waits for another exclusive diagnostic operation', (
    tester,
  ) async {
    final harness = _Harness();
    final transport = _KwpTransport();
    harness.attach(transport);
    harness.shared.attachUdsClient(UdsClient(_UnusedUdsLink()));
    final releaseOperation = Completer<void>();
    final activeOperation = harness.shared.runExclusive(
      () => releaseOperation.future,
    );
    addTearDown(() async {
      if (!releaseOperation.isCompleted) {
        releaseOperation.complete();
        await activeOperation;
      }
      await harness.cleanup(tester);
    });

    await tester.pumpWidget(const MaterialApp(home: LegacyKwpPage()));
    expect(harness.shared.protocolReady, isTrue);
    expect(harness.shared.operationBusy, isTrue);
    expect(find.byKey(const ValueKey('kwp-configure')), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(find.byKey(const ValueKey('kwp-configure')))
          .onPressed,
      isNull,
    );
    expect(transport.writes, isEmpty);

    releaseOperation.complete();
    await activeOperation;
    await tester.pump();
    expect(harness.shared.protocolReady, isTrue);
    expect(transport.writes, isEmpty);
  });

  testWidgets(
    'DTC text uses the optional ECU key and leaves the third row byte opaque',
    (tester) async {
      final harness = _Harness();
      final transport = _KwpTransport();
      harness.attach(transport);
      transport.reply(
        '1802FFFF',
        _KwpTransport._frame([0x58, 1, 0x10, 0x40, 0xaa]),
      );
      addTearDown(() => harness.cleanup(tester));

      await tester.pumpWidget(
        const MaterialApp(home: LegacyKwpPage(originalEcuKey: 'cuMRBMSMP1')),
      );
      await _configure(tester);
      await tester.tap(find.byKey(const ValueKey('kwp-read-dtcs')));
      await tester.pumpAndSettle();

      expect(find.textContaining('Oxygen sensor heating 1'), findsOneWidget);
      expect(find.textContaining('0xAA (uninterpreted)'), findsOneWidget);
      expect(find.textContaining('Confirmed'), findsNothing);
    },
  );

  testWidgets('DTC clear requires confirmation and verifies with readback', (
    tester,
  ) async {
    final harness = _Harness();
    final transport = _KwpTransport();
    harness.attach(transport);
    addTearDown(() => harness.cleanup(tester));

    await tester.pumpWidget(const MaterialApp(home: LegacyKwpPage()));
    await _configure(tester);
    final writesBeforeDialog = transport.writes.length;

    await tester.tap(find.byKey(const ValueKey('kwp-clear-dtcs')));
    await tester.pumpAndSettle();
    expect(find.text('Clear legacy KWP fault codes?'), findsOneWidget);
    expect(transport.writes.length, writesBeforeDialog);
    expect(transport.writes, isNot(contains('14FFFF')));

    await tester.tap(find.byKey(const ValueKey('kwp-clear-cancel')));
    await tester.pumpAndSettle();
    expect(transport.writes, isNot(contains('14FFFF')));

    await tester.tap(find.byKey(const ValueKey('kwp-clear-dtcs')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('kwp-clear-confirm')));
    await tester.pumpAndSettle();

    expect(transport.writes, contains('14FFFF'));
    expect(
      transport.writes.where((command) => command == '1802FFFF'),
      hasLength(1),
    );
    expect(
      find.textContaining('0 DTC(s) returned on readback'),
      findsOneWidget,
    );
  });

  testWidgets('late identify result is discarded after adapter reconnection', (
    tester,
  ) async {
    final harness = _Harness();
    final oldTransport = _KwpTransport();
    final oldSession = harness.attach(oldTransport, identity: 'old adapter');
    final delayedIdentity = Completer<String>();
    oldTransport.replyFuture('1A80', delayedIdentity.future);
    addTearDown(() => harness.cleanup(tester));

    await tester.pumpWidget(const MaterialApp(home: LegacyKwpPage()));
    await _configure(tester);
    await tester.tap(find.byKey(const ValueKey('kwp-identify')));
    await tester.pump();
    expect(oldTransport.writes, contains('1A80'));

    final newTransport = _KwpTransport();
    final newSession = harness.attach(newTransport, identity: 'new adapter');
    await tester.pumpAndSettle();
    delayedIdentity.complete(_KwpTransport._frame([0x5a, 0x80, 0x99]));
    await tester.pumpAndSettle();

    expect(identical(harness.shared.elmSession, newSession), isTrue);
    expect(harness.shared.connected, isTrue);
    expect(find.textContaining('5A 80 99'), findsNothing);
    expect(
      find.text('Adapter changed. Configure KWP again before continuing.'),
      findsOneWidget,
    );
    expect(identical(harness.shared.elmSession, oldSession), isFalse);
  });

  testWidgets('popping the KWP page leaves the shared adapter connected', (
    tester,
  ) async {
    final harness = _Harness();
    final transport = _KwpTransport();
    final session = harness.attach(transport);
    addTearDown(() => harness.cleanup(tester));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => FilledButton(
              onPressed: () => Navigator.of(context).push<void>(
                MaterialPageRoute(builder: (_) => const LegacyKwpPage()),
              ),
              child: const Text('Open KWP'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open KWP'));
    await tester.pumpAndSettle();
    await _configure(tester);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    expect(harness.shared.connected, isTrue);
    expect(identical(harness.shared.elmSession, session), isTrue);
    expect(transport.closed, isFalse);
  });

  testWidgets('legacy cluster service reset executes 3B writes and updates status', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final harness = _Harness();
    final transport = _KwpTransport();
    harness.attach(transport);
    addTearDown(() => harness.cleanup(tester));

    await tester.pumpWidget(const MaterialApp(home: LegacyKwpPage()));
    await _configure(tester);

    final resetCardTitle = find.text('Legacy Cluster Service Reset (Service 0x3B)');
    await tester.scrollUntilVisible(
      resetCardTitle,
      50,
      scrollable: find.byType(Scrollable).first,
    );
    expect(resetCardTitle, findsOneWidget);

    // Scroll to the button and execute reset all
    final resetAllButton = find.byKey(const ValueKey('kwp-service-reset-all'));
    await tester.scrollUntilVisible(
      resetAllButton,
      50,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(resetAllButton);
    await tester.pumpAndSettle();

    // Verify 3B requests were sent
    final writes3b = transport.writes.where((c) => c.startsWith('3B')).toList();
    expect(writes3b.length, 3);
    // 3B 10 (clock), 3B 11 (service date), 3B 12 (mileage)
    expect(writes3b[0].startsWith('3B10'), isTrue);
    expect(writes3b[1].startsWith('3B11'), isTrue);
    expect(writes3b[2].startsWith('3B12'), isTrue);

    // Verify status update indicates acknowledgment without independent readback
    expect(find.textContaining('acknowledged Service 0x3B write'), findsOneWidget);
    expect(find.textContaining('independent readback verification is unsupported'), findsOneWidget);
  });
}
