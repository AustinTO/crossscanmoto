import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:fake_async/fake_async.dart';
import 'package:crossscanmoto/diagnostics/elm_session.dart';
import 'package:crossscanmoto/diagnostics/kwp_client.dart';
import 'package:crossscanmoto/diagnostics/uds_client.dart';
import 'support/scripted_adapter_transport.dart';
import 'support/scripted_request_links.dart';

void main() {
  test(
    'replays source-backed KWP setup command order with fragmented prompts',
    () async {
      // Command literals/order are documented from APK 1.83 i3/g.c0 in
      // assets/research/historical-protocol-1.83.md. The adapter OK replies here
      // are synthetic transport mechanics, not original-executed parity data.
      final fixture =
          jsonDecode(
                File('test/fixtures/kwp_setup_1_83.json').readAsStringSync(),
              )
              as Map<String, dynamic>;
      final commands = (fixture['commands'] as List).cast<String>();
      final transport = ScriptedAdapterTransport([
        for (final command in commands)
          ScriptedElmExchange(command, const ['O', 'K\r>']),
      ]);
      final session = ElmSession(transport);
      final link = BmwBikeKwpLink(session);

      expect(await link.configure(ecuAddress: 0x12), isTrue);
      expect(transport.writes, [for (final command in commands) '$command\r']);
      transport.verifyComplete();
      await session.close();
    },
  );

  test('rejects any command beyond the scripted replay queue', () async {
    final transport = ScriptedAdapterTransport([
      const ScriptedElmExchange('ATI', ['ELM327\r>']),
    ]);
    final session = ElmSession(transport);

    expect((await session.command('ATI')).text, 'ELM327');
    await expectLater(
      session.command('ATRV'),
      throwsA(
        isA<StateError>().having(
          (error) => error.message,
          'unexpected command diagnostic',
          contains('Unexpected adapter command: ATRV'),
        ),
      ),
    );
    expect(() => transport.verifyComplete(), returnsNormally);
    await session.close();
  });

  test(
    'times out deterministically when a command never receives a prompt',
    () async {
      final transport = ScriptedAdapterTransport([
        const ScriptedElmExchange('ATI', ['ELM327']),
      ]);
      late ElmSession session;
      final async = FakeAsync();
      var timedOut = false;
      async.run((_) {
        session = ElmSession(transport);
        final request = session.command(
          'ATI',
          timeout: const Duration(seconds: 1),
        );
        request.then<void>(
          (_) {},
          onError: (Object error) {
            timedOut = error is TimeoutException;
          },
        );
        async.flushMicrotasks();
        async.elapse(const Duration(seconds: 1));
        async.flushMicrotasks();
      });
      expect(timedOut, isTrue);
      await session.close();
    },
  );

  test('disconnect fails an in-flight scripted request', () async {
    final transport = ScriptedAdapterTransport([
      const ScriptedElmExchange('ATI', []),
    ]);
    final session = ElmSession(transport);
    final request = session.command('ATI');
    final expectation = expectLater(request, throwsA(isA<StateError>()));
    await Future<void>.delayed(Duration.zero);
    await transport.disconnect();

    await expectation;
    await session.close();
  });

  test('reports unconsumed scripted commands', () async {
    final transport = ScriptedAdapterTransport([
      const ScriptedElmExchange('ATI', ['ELM327\r>']),
      const ScriptedElmExchange('ATRV', ['12.6V\r>']),
    ]);
    final session = ElmSession(transport);

    expect(transport.writes, isEmpty);
    expect(() => transport.verifyComplete(), throwsStateError);
    await session.close();
  });

  test(
    'strict request links preserve synthetic UDS negative reply handling',
    () async {
      final link = ScriptedUdsRequestLink([
        const ScriptedRequestExchange([0x22, 0xf1, 0x90], [0x7f, 0x22, 0x31]),
      ]);

      await expectLater(
        UdsClient(link).readDataByIdentifier(0xf190),
        throwsA(isA<UdsNegativeResponseException>()),
      );
      expect(link.requests, [
        [0x22, 0xf1, 0x90],
      ]);
      link.verifyComplete();
    },
  );

  test(
    'strict request link fails loudly on an unexpected application request',
    () async {
      final link = ScriptedKwpRequestLink([
        const ScriptedRequestExchange([0x18, 0x02, 0xff, 0xff], [0x58]),
      ], startCommunicationReplies: const []);

      await expectLater(
        link.request([0x14, 0xff, 0xff]),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'request mismatch diagnostic',
            contains('Expected KWP request'),
          ),
        ),
      );
      expect(link.requests, [
        [0x14, 0xff, 0xff],
      ]);
      expect(() => link.verifyComplete(), throwsStateError);
    },
  );

  test(
    'surfaces a scripted KWP pending response when no final frame arrives',
    () async {
      final setupCommands =
          (jsonDecode(
                    File(
                      'test/fixtures/kwp_setup_1_83.json',
                    ).readAsStringSync(),
                  )
                  as Map<String, dynamic>)['commands']
              as List;
      final transport = ScriptedAdapterTransport([
        for (final command in setupCommands.cast<String>())
          ScriptedElmExchange(command, const ['OK\r>']),
        const ScriptedElmExchange('17', ['03 7F 17 78 00\r>']),
      ]);
      final session = ElmSession(transport);
      final link = BmwBikeKwpLink(session);
      expect(await link.configure(ecuAddress: 0x12), isTrue);

      await expectLater(
        link.request([0x17]),
        throwsA(isA<KwpResponsePendingException>()),
      );
      transport.verifyComplete();
      await session.close();
    },
  );
}
