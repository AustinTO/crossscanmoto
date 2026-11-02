import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:crossscanmoto/diagnostics/recovered_actuators.dart';
import 'package:crossscanmoto/diagnostics/uds_client.dart';

class _FakeUdsLink implements UdsRequestLink {
  final requests = <List<int>>[];
  final responses = <String, List<int>>{};
  final failingRequests = <String>{};
  final delayedResponses = <String, Completer<List<int>>>{};
  final requestStarted = Completer<String>();
  final timeouts = <Duration?>[];

  String key(List<int> bytes) => bytes.join(',');

  @override
  Future<List<int>> request(List<int> payload, {Duration? timeout}) async {
    final request = List<int>.unmodifiable(payload);
    requests.add(request);
    timeouts.add(timeout);
    if (failingRequests.contains(key(request))) {
      throw StateError('simulated request failure');
    }
    final delayed = delayedResponses[key(request)];
    if (delayed != null) {
      if (!requestStarted.isCompleted) requestStarted.complete(key(request));
      return delayed.future;
    }
    return responses[key(request)] ?? [request.first + 0x40];
  }
}

RecoveredActuatorPosition _bmsxFuelInjectorPosition() {
  final definition = recoveredActuatorsByEcu['cuX_BMSX']!.singleWhere(
    (actuator) => actuator.id == 1,
  );
  return definition.positions.singleWhere((position) => position.id == 1);
}

void main() {
  test('compiler output preserves ECU-parent-position-command joins', () {
    final actuators = recoveredActuatorsByEcu['cuX_BMSX']!;
    final fuelInjector = actuators.singleWhere((actuator) => actuator.id == 1);
    final position = fuelInjector.positions.singleWhere((item) => item.id == 1);

    expect(fuelInjector.name, 'Fuel injector');
    expect(position.actuatorId, fuelInjector.id);
    expect(position.title, 'Fuel injector 1');
    expect(position.instructionTextId, 106052);
    expect(position.off!.positionId, position.id);
    expect(position.commands.map((command) => command.action), [
      RecoveredActuatorAction.on,
      RecoveredActuatorAction.off,
    ]);
  });

  test(
    'table reply-prefix mismatch is retained without rewriting requests',
    () async {
      final position = _bmsxFuelInjectorPosition();
      final on = position.on!;
      final off = position.off!;
      expect(on.request, [
        0x2f,
        0x62,
        0x50,
        0x03,
        0x00,
        0x64,
        0x00,
        0x01,
        0xc0,
      ]);
      expect(off.request, [0x2f, 0x62, 0x50, 0x00, 0xff]);
      expect(off.responsePrefix, [0x6f, 0x62, 0x5c, 0x00]);
      expect(off.responsePrefixEchoesRequest, isFalse);
      expect(position.isSupported, isTrue);

      final link = _FakeUdsLink();
      link.responses[link.key(on.request)] = [0x6f, 0x62, 0x50, 0x03];
      link.responses[link.key(off.request)] = [0x6f, 0x62, 0x5c, 0x00];
      final waited = <Duration>[];
      final executor = RecoveredActuatorExecutor(
        wait: (duration) async => waited.add(duration),
      );

      await executor.run(link: link, position: position);

      expect(link.requests, [on.request, off.request]);
      expect(waited, [const Duration(seconds: 10)]);
      expect(link.timeouts, everyElement(const Duration(seconds: 3)));
    },
  );

  test('Off is sent after an activation request fails', () async {
    final position = _bmsxFuelInjectorPosition();
    final link = _FakeUdsLink()
      ..failingRequests.add(linkKey(position.on!.request));
    final executor = RecoveredActuatorExecutor(wait: (_) async {});

    await expectLater(
      executor.run(link: link, position: position),
      throwsA(isA<RecoveredActuatorExecutionException>()),
    );

    expect(link.requests, [position.on!.request, position.off!.request]);
  });

  test(
    'Off is still attempted when the activation returns a negative reply',
    () async {
      final position = _bmsxFuelInjectorPosition();
      final link = _FakeUdsLink()
        ..responses[linkKey(position.on!.request)] = [0x7f, 0x2f, 0x22];
      final executor = RecoveredActuatorExecutor(wait: (_) async {});

      await expectLater(
        executor.run(link: link, position: position),
        throwsA(isA<RecoveredActuatorExecutionException>()),
      );
      expect(link.requests.last, position.off!.request);
    },
  );

  test('concurrent runs serialize complete On/wait/Off cycles', () async {
    final position = _bmsxFuelInjectorPosition();
    final link = _FakeUdsLink();
    final firstWaitStarted = Completer<void>();
    final releaseFirstWait = Completer<void>();
    var waitCount = 0;
    final firstExecutor = RecoveredActuatorExecutor(
      wait: (_) async {
        waitCount++;
        if (waitCount == 1) {
          firstWaitStarted.complete();
          await releaseFirstWait.future;
        }
      },
    );
    final secondExecutor = RecoveredActuatorExecutor(wait: (_) async {});

    final first = firstExecutor.run(link: link, position: position);
    await firstWaitStarted.future;
    final second = secondExecutor.run(link: link, position: position);
    await Future<void>.delayed(Duration.zero);

    expect(link.requests, [position.on!.request]);
    releaseFirstWait.complete();
    await Future.wait([first, second]);
    expect(link.requests, [
      position.on!.request,
      position.off!.request,
      position.on!.request,
      position.off!.request,
    ]);
  });

  test('activation duration cannot exceed the configured hard bound', () async {
    final position = _bmsxFuelInjectorPosition();
    final executor = RecoveredActuatorExecutor(
      maximumDuration: const Duration(seconds: 5),
      wait: (_) async {},
    );

    await expectLater(
      executor.run(link: _FakeUdsLink(), position: position),
      throwsRangeError,
    );
  });

  test('a queued run cancelled before its turn sends no commands', () async {
    final position = _bmsxFuelInjectorPosition();
    final link = _FakeUdsLink();
    final firstWaitStarted = Completer<void>();
    final releaseFirstWait = Completer<void>();
    final cancellation = Completer<void>();
    final firstExecutor = RecoveredActuatorExecutor(
      wait: (_) async {
        firstWaitStarted.complete();
        await releaseFirstWait.future;
      },
    );
    final queuedExecutor = RecoveredActuatorExecutor(wait: (_) async {});

    final first = firstExecutor.run(link: link, position: position);
    await firstWaitStarted.future;
    final queued = queuedExecutor.run(
      link: link,
      position: position,
      cancellation: cancellation.future,
    );
    cancellation.complete();
    releaseFirstWait.complete();

    await first;
    await expectLater(
      queued,
      throwsA(isA<RecoveredActuatorCancelledException>()),
    );
    expect(link.requests, [position.on!.request, position.off!.request]);
  });

  test(
    'cancellation during the activation wait stops and reports cancelled',
    () async {
      final position = _bmsxFuelInjectorPosition();
      final link = _FakeUdsLink();
      final waitStarted = Completer<void>();
      final cancellation = Completer<void>();
      final executor = RecoveredActuatorExecutor(
        wait: (_) async {
          waitStarted.complete();
          await cancellation.future;
        },
      );

      final run = executor.run(
        link: link,
        position: position,
        cancellation: cancellation.future,
      );
      await waitStarted.future;
      cancellation.complete();

      await expectLater(
        run,
        throwsA(isA<RecoveredActuatorCancelledException>()),
      );
      expect(link.requests, [position.on!.request, position.off!.request]);
    },
  );

  test(
    'cancellation during Start still attempts Off before returning',
    () async {
      final position = recoveredActuatorsByEcu['cuX_ABS']!
          .expand((actuator) => actuator.positions)
          .firstWhere((candidate) => candidate.start != null);
      final start = position.start!;
      final link = _FakeUdsLink();
      final startResponse = Completer<List<int>>();
      link.delayedResponses[link.key(start.request)] = startResponse;
      link.responses[link.key(start.request)] = [0x50, 0x03];
      final cancellation = Completer<void>();
      final executor = RecoveredActuatorExecutor(wait: (_) async {});

      final run = executor.run(
        link: link,
        position: position,
        cancellation: cancellation.future,
      );
      expect(await link.requestStarted.future, link.key(start.request));
      cancellation.complete();
      startResponse.complete([0x50, 0x03]);

      await expectLater(
        run,
        throwsA(isA<RecoveredActuatorCancelledException>()),
      );
      expect(link.requests, [start.request, position.off!.request]);
      expect(link.requests, isNot(contains(position.activation!.request)));
    },
  );
}

String linkKey(List<int> bytes) => bytes.join(',');
