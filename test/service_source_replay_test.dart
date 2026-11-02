import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crossscanmoto/diagnostics/service_reset_protocol.dart';
import 'package:crossscanmoto/diagnostics/uds_client.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/scripted_request_links.dart';

int _did(List<int> request) => (request[1] << 8) | request[2];

List<int> _replyData(List<int> fullResponse) => fullResponse.sublist(3);

BmwServiceResetAction _action(String name) => switch (name) {
  'all' => BmwServiceResetAction.all,
  'vehicleDateTime' => BmwServiceResetAction.vehicleDateTime,
  'nextServiceDate' => BmwServiceResetAction.nextServiceDate,
  'nextServiceMileage' => BmwServiceResetAction.nextServiceMileage,
  _ => throw ArgumentError.value(name, 'name'),
};

void main() {
  final fixture =
      jsonDecode(
            File(
              'test/fixtures/service_dispatch_goldens.json',
            ).readAsStringSync(),
          )
          as Map<String, dynamic>;
  final routes = (fixture['routes'] as List).cast<Map<String, dynamic>>();
  final actions = (fixture['actions'] as List).cast<Map<String, dynamic>>();

  group('MotoScan 1.110 UDS service dispatch source vectors', () {
    test(
      'pins all enabled CF_SERVICE routes to their source selection rows',
      () {
        const expected = <String, int>{
          'cuX_KOMBI': 1017856,
          'cuX_KOMB50': 1017936,
          'cuX_KOMB53': 1017952,
          'cuX_KOMB17': 1017984,
          'cuX_KOMB46': 1018000,
          'cuX_KOMB18': 1019968,
          'cuX_KOMB03': 1020000,
          'cuX_KOMBLO': 1020016,
          'cuX_KOMBHI': 1020032,
          'cuX_KOMBB2': 1020034,
          'cuX_KOMB_A': 1020037,
          'cuX_CCP': 1020064,
        };
        expect(fixture['source']['classification'], contains('STATIC_GOLDEN'));
        expect(routes, hasLength(expected.length));
        expect({
          for (final route in routes)
            route['ecu_key'] as String: route['response_id'] as int,
        }, expected);
        for (final route in routes) {
          final row = route['functions_raw_row'] as String;
          final fields = row.split(';');
          expect(fields[0], '12', reason: route['ecu_key'] as String);
          expect(fields[1], '1', reason: route['ecu_key'] as String);
          expect(route['function_category'], 'CF_SERVICE');
          expect(route['handler_family'], contains('sl0.C'));
          expect(
            BmwServiceResetCatalog.supportsEcuKey(route['ecu_key'] as String),
            isTrue,
          );
          final functionPath =
              route['source_refs'].cast<Map<String, dynamic>>().singleWhere(
                    (source) =>
                        (source['path'] as String).endsWith('/FUNCTIONS.json'),
                  )['path']
                  as String;
          expect(File(functionPath).readAsStringSync(), contains(row));
        }
      },
    );

    for (final route in routes) {
      for (final action in actions) {
        final ecuKey = route['ecu_key'] as String;
        final actionName = action['action'] as String;
        test(
          '$ecuKey ${action['event_name']} replays exact source bytes',
          () async {
            final writes = (action['writes'] as List)
                .cast<Map<String, dynamic>>();
            final readbacks = (action['post_readback'] as List)
                .cast<Map<String, dynamic>>();
            final exchanges = <ScriptedRequestExchange>[
              for (final write in writes)
                ScriptedRequestExchange(
                  (write['request'] as List).cast<int>(),
                  (write['positive_ack_reply'] as List).cast<int>(),
                ),
              for (final read in readbacks)
                ScriptedRequestExchange(
                  (read['request'] as List).cast<int>(),
                  (read['reply'] as List).cast<int>(),
                ),
            ];
            final link = ScriptedUdsRequestLink(exchanges);
            final delays = <Duration>[];
            final input = action['input'] as Map<String, dynamic>;
            final result =
                await BmwServiceResetProtocol(
                  link: link,
                  profile: BmwServiceResetProfile.udsServiceData,
                  ecuKey: ecuKey,
                  delay: (duration) async => delays.add(duration),
                ).execute(
                  action: _action(actionName),
                  vehicleDateTime: DateTime.parse(
                    input['vehicle_date_time_local'] as String,
                  ),
                  nextServiceDate: DateTime.parse(
                    input['next_service_date_local'] as String,
                  ),
                  nextServiceMileage: input['next_service_mileage_km'] as int,
                );

            final expectedWrites = writes
                .map((write) => (write['request'] as List).cast<int>())
                .toList();
            final expectedReadbacks = readbacks
                .map((read) => (read['request'] as List).cast<int>())
                .toList();
            expect(link.requests, [...expectedWrites, ...expectedReadbacks]);
            expect(
              result.writtenDids,
              writes.map((write) => write['did'] as int).toList(),
            );
            expect(result.readback, {
              for (final read in readbacks)
                _did((read['request'] as List).cast<int>()): _replyData(
                  (read['reply'] as List).cast<int>(),
                ),
            });
            expect(result.odometerKilometers, 42);
            expect(
              delays,
              List<Duration>.filled(
                writes.length,
                const Duration(milliseconds: 1500),
              ),
            );
            link.verifyComplete();
          },
        );
      }
    }

    test(
      'rejects the former type-8 BMS ADAPTIONS key without a write',
      () async {
        final link = ScriptedUdsRequestLink(const []);
        final date = DateTime(2026, 11, 2, 12, 34, 56);
        await expectLater(
          BmwServiceResetProtocol(
            link: link,
            profile: BmwServiceResetProfile.udsServiceData,
            ecuKey: 'cuX_BMSX',
            delay: (_) async {},
          ).execute(
            action: BmwServiceResetAction.all,
            vehicleDateTime: date,
            nextServiceDate: DateTime(2027, 6, 15),
            nextServiceMileage: 54321,
          ),
          throwsUnsupportedError,
        );
        expect(link.requests, isEmpty);
      },
    );

    test(
      'rejects a synthetic NRC to the first source write and stops',
      () async {
        final route = routes.first;
        final action = actions.firstWhere(
          (item) => item['event_name'] == 'SI_DATE_CAR',
        );
        final write = (action['writes'] as List)
            .cast<Map<String, dynamic>>()
            .single;
        final link = ScriptedUdsRequestLink([
          ScriptedRequestExchange(
            (write['request'] as List).cast<int>(),
            (write['synthetic_negative_reply'] as List).cast<int>(),
          ),
        ]);
        final delays = <Duration>[];
        await expectLater(
          BmwServiceResetProtocol(
            link: link,
            profile: BmwServiceResetProfile.udsServiceData,
            ecuKey: route['ecu_key'] as String,
            delay: (duration) async => delays.add(duration),
          ).execute(
            action: BmwServiceResetAction.vehicleDateTime,
            vehicleDateTime: DateTime(2026, 11, 2, 12, 34, 56),
            nextServiceDate: DateTime(2027, 6, 15),
            nextServiceMileage: 54321,
          ),
          throwsA(isA<UdsNegativeResponseException>()),
        );
        expect(link.requests, [(write['request'] as List).cast<int>()]);
        expect(delays, [const Duration(milliseconds: 1500)]);
        link.verifyComplete();
      },
    );

    test('stops on a synthetic negative post-readback response', () async {
      final route = routes.firstWhere(
        (item) => item['ecu_key'] == 'cuX_KOMB18',
      );
      final action = actions.firstWhere(
        (item) => item['event_name'] == 'SI_DATE',
      );
      final write = (action['writes'] as List)
          .cast<Map<String, dynamic>>()
          .single;
      final reads = (action['post_readback'] as List)
          .cast<Map<String, dynamic>>();
      final exchanges = <ScriptedRequestExchange>[
        ScriptedRequestExchange(
          (write['request'] as List).cast<int>(),
          (write['positive_ack_reply'] as List).cast<int>(),
        ),
        ScriptedRequestExchange(
          (reads.first['request'] as List).cast<int>(),
          (action['synthetic_readback_negative_reply'] as List).cast<int>(),
        ),
      ];
      final link = ScriptedUdsRequestLink(exchanges);
      await expectLater(
        BmwServiceResetProtocol(
          link: link,
          profile: BmwServiceResetProfile.udsServiceData,
          ecuKey: route['ecu_key'] as String,
          delay: (_) async {},
        ).execute(
          action: BmwServiceResetAction.nextServiceDate,
          vehicleDateTime: DateTime(2026, 11, 2, 12, 34, 56),
          nextServiceDate: DateTime(2027, 6, 15),
          nextServiceMileage: 54321,
        ),
        throwsA(isA<UdsNegativeResponseException>()),
      );
      expect(link.requests, [
        (write['request'] as List).cast<int>(),
        (reads.first['request'] as List).cast<int>(),
      ]);
      link.verifyComplete();
    });

    test(
      'does not accept a mismatched synthetic readback as success',
      () async {
        final route = routes.firstWhere(
          (item) => item['ecu_key'] == 'cuX_KOMB18',
        );
        final action = actions.firstWhere(
          (item) => item['event_name'] == 'SI_DATE',
        );
        final write = (action['writes'] as List)
            .cast<Map<String, dynamic>>()
            .single;
        final reads = (action['post_readback'] as List)
            .cast<Map<String, dynamic>>();
        final exchanges = <ScriptedRequestExchange>[
          ScriptedRequestExchange(
            (write['request'] as List).cast<int>(),
            (write['positive_ack_reply'] as List).cast<int>(),
          ),
          for (final read in reads)
            ScriptedRequestExchange(
              (read['request'] as List).cast<int>(),
              read['request'] == reads.last['request']
                  ? [0x62, 0xe1, 0x2c, 0x10, 0x06, 0x07, 0xeb]
                  : (read['reply'] as List).cast<int>(),
            ),
        ];
        final link = ScriptedUdsRequestLink(exchanges);
        await expectLater(
          BmwServiceResetProtocol(
            link: link,
            profile: BmwServiceResetProfile.udsServiceData,
            ecuKey: route['ecu_key'] as String,
            delay: (_) async {},
          ).execute(
            action: BmwServiceResetAction.nextServiceDate,
            vehicleDateTime: DateTime(2026, 11, 2, 12, 34, 56),
            nextServiceDate: DateTime(2027, 6, 15),
            nextServiceMileage: 54321,
          ),
          throwsFormatException,
        );
        link.verifyComplete();
      },
    );

    test('validates mileage bounds before any write', () async {
      final route = routes.first;
      for (final mileage in [-1, 0x10000]) {
        final link = ScriptedUdsRequestLink(const []);
        await expectLater(
          BmwServiceResetProtocol(
            link: link,
            profile: BmwServiceResetProfile.udsServiceData,
            ecuKey: route['ecu_key'] as String,
            delay: (_) async {},
          ).execute(
            action: BmwServiceResetAction.nextServiceMileage,
            vehicleDateTime: DateTime(2026, 11, 2, 12, 34, 56),
            nextServiceDate: DateTime(2027, 6, 15),
            nextServiceMileage: mileage,
          ),
          throwsRangeError,
        );
        expect(link.requests, isEmpty);
      }
    });

    test('cancels before the first write with no request', () async {
      final route = routes.firstWhere(
        (item) => item['ecu_key'] == 'cuX_KOMB18',
      );
      final link = ScriptedUdsRequestLink(const []);
      await expectLater(
        BmwServiceResetProtocol(
          link: link,
          profile: BmwServiceResetProfile.udsServiceData,
          ecuKey: route['ecu_key'] as String,
          shouldAbort: () => true,
          delay: (_) async {},
        ).execute(
          action: BmwServiceResetAction.all,
          vehicleDateTime: DateTime(2026, 11, 2, 12, 34, 56),
          nextServiceDate: DateTime(2027, 6, 15),
          nextServiceMileage: 54321,
        ),
        throwsA(
          isA<BmwServiceResetCancelledException>().having(
            (error) => error.isPartial,
            'isPartial',
            isFalse,
          ),
        ),
      );
      expect(link.requests, isEmpty);
    });

    test(
      'session change while first ACK is held cancels before later writes',
      () async {
        final route = routes.firstWhere(
          (item) => item['ecu_key'] == 'cuX_KOMB18',
        );
        final action = actions.firstWhere(
          (item) => item['event_name'] == 'SI_ALL',
        );
        final firstWrite = (action['writes'] as List)
            .cast<Map<String, dynamic>>()
            .first;
        final link = ScriptedUdsRequestLink([
          ScriptedRequestExchange(
            (firstWrite['request'] as List).cast<int>(),
            (firstWrite['positive_ack_reply'] as List).cast<int>(),
          ),
        ]);
        final held = Completer<List<int>>();
        link.heldReply = held;
        var sessionGeneration = 1;
        const startingGeneration = 1;
        final pending =
            BmwServiceResetProtocol(
              link: link,
              profile: BmwServiceResetProfile.udsServiceData,
              ecuKey: route['ecu_key'] as String,
              shouldAbort: () => sessionGeneration != startingGeneration,
              delay: (_) async {},
            ).execute(
              action: BmwServiceResetAction.all,
              vehicleDateTime: DateTime(2026, 11, 2, 12, 34, 56),
              nextServiceDate: DateTime(2027, 6, 15),
              nextServiceMileage: 54321,
            );

        for (
          var attempt = 0;
          attempt < 20 && link.requests.isEmpty;
          attempt++
        ) {
          await Future<void>.delayed(Duration.zero);
        }
        expect(link.requests, [(firstWrite['request'] as List).cast<int>()]);
        sessionGeneration++;
        held.complete((firstWrite['positive_ack_reply'] as List).cast<int>());
        await expectLater(
          pending,
          throwsA(
            isA<BmwServiceResetCancelledException>()
                .having((error) => error.writtenDids, 'writtenDids', [0xe12b])
                .having((error) => error.isPartial, 'isPartial', isTrue)
                .having((error) => error.readback, 'readback', isEmpty),
          ),
        );
        expect(link.requests, [(firstWrite['request'] as List).cast<int>()]);
      },
    );
  });

  group('unresolved legacy routing boundary', () {
    test('does not invent a KWP ECU-key/function-gate join', () {
      final unresolved =
          fixture['unresolved_legacy_kwp'] as Map<String, dynamic>;
      expect(unresolved['status'].toString().toLowerCase(), contains('unresolved'));
      expect(unresolved['reason'], contains('No source-backed edge maps'));
      expect(
        unresolved['CF_SERVICE_FUNCTIONS_rows_without_KWP_join'],
        hasLength(9),
      );
      expect(
        unresolved['CF_SERVICE_FUNCTIONS_rows_without_KWP_join'],
        isNotEmpty,
      );
    });
  });
}
