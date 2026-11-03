import 'package:flutter_test/flutter_test.dart';
import 'package:crossscanmoto/diagnostics/source_qualified_catalog.dart';
import 'package:crossscanmoto/diagnostics/typed_service_step.dart';
import 'package:crossscanmoto/diagnostics/uds_client.dart';
import 'package:crossscanmoto/diagnostics/vehicle_catalog.dart';

class _FakeUdsLink implements UdsRequestLink {
  final List<List<int>> sentRequests = [];
  List<int> nextReply = [0x6F];

  @override
  Future<List<int>> request(List<int> payload, {Duration? timeout}) async {
    sentRequests.add(List.from(payload));
    return nextReply;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Source Qualified Catalog & Profile Migration', () {
    test('VehicleProfile migrates ambiguous R nineT to K21 platform 1 for 2015', () {
      final profile = VehicleProfile(
        modelName: 'R nineT',
        modelYear: 2015,
      );
      expect(profile.ebr, 'K21');
      expect(profile.platformId, '1');
      expect(profile.sourceQualifiedId, 'source:motoscan:platform:1:K21');
      expect(profile.needsDisambiguation, isFalse);
    });

    test('VehicleProfile migrates ambiguous R nineT to K21 platform 2 for 2018', () {
      final profile = VehicleProfile(
        modelName: 'R nineT',
        modelYear: 2018,
      );
      expect(profile.ebr, 'K21');
      expect(profile.platformId, '2');
      expect(profile.sourceQualifiedId, 'source:motoscan:platform:2:K21');
      expect(profile.needsDisambiguation, isFalse);
    });

    test('VehicleProfile flags R nineT without year for disambiguation', () {
      final profile = VehicleProfile(
        modelName: 'R nineT',
      );
      expect(profile.ebr, 'K21');
      expect(profile.needsDisambiguation, isTrue);
    });

    test('VehicleProfile preserves K46 2010–2011 platform 1 and 2013 platform 2', () {
      final p2010 = VehicleProfile(modelName: 'S 1000 RR', modelYear: 2010);
      expect(p2010.platformId, '1');
      expect(p2010.sourceQualifiedId, 'source:motoscan:platform:1:K46_2010');

      final p2014 = VehicleProfile(modelName: 'S 1000 RR', modelYear: 2014);
      expect(p2014.platformId, '2');
      expect(p2014.sourceQualifiedId, 'source:motoscan:platform:2:K46');
    });

    test('VehicleProfile routes CE 04 to K07 electric platform', () {
      final ce04 = VehicleProfile(modelName: 'CE 04');
      expect(ce04.ebr, 'K07');
      expect(ce04.platformId, '2');
      expect(ce04.sourceQualifiedId, 'source:biketune:1.9.1:bike:K07');
    });
  });

  group('Typed Service Step Executor', () {
    test('Info step prompts operator and completes on approval', () async {
      const step = BiketuneServiceStep(
        id: 101,
        functionPk: 1,
        stepOrder: 1,
        kind: 'info',
        text: 'Connect battery charger before proceeding.',
      );
      final link = _FakeUdsLink();
      var prompted = false;

      final executor = TypedServiceStepExecutor(
        link: link,
        onPrompt: (p) async {
          prompted = true;
          return true;
        },
      );

      final result = await executor.executeStep(step);
      expect(prompted, isTrue);
      expect(result.state, StepExecutionState.completed);
      expect(link.sentRequests, isEmpty);
    });

    test('Info step cancels cleanly if operator declines', () async {
      const step = BiketuneServiceStep(
        id: 102,
        functionPk: 1,
        stepOrder: 1,
        kind: 'info',
        text: 'Proceed?',
      );
      final link = _FakeUdsLink();

      final executor = TypedServiceStepExecutor(
        link: link,
        onPrompt: (p) async => false,
      );

      final result = await executor.executeStep(step);
      expect(result.state, StepExecutionState.cancelled);
      expect(link.sentRequests, isEmpty);
    });

    test('Uncompiled EDIABAS job step is marked unsupported without sending bytes', () async {
      const step = BiketuneServiceStep(
        id: 103,
        functionPk: 1,
        stepOrder: 2,
        kind: 'routine',
        requestPdu: 'X_ABS::STEUERN_IO ARG;ABS_PUMPE_MR;STA;1',
      );
      final link = _FakeUdsLink();
      final executor = TypedServiceStepExecutor(
        link: link,
        allowPhysicalExecution: true,
      );

      final result = await executor.executeStep(step);
      expect(result.state, StepExecutionState.unsupported);
      expect(link.sentRequests, isEmpty);
    });

    test('Pump-hold step sends request, holds, and guarantees stop PDU execution', () async {
      const step = BiketuneServiceStep(
        id: 104,
        functionPk: 1,
        stepOrder: 1,
        kind: 'pump-hold',
        requestPdu: '2F,E0,DA,03,01',
        positiveResponse: '6F',
        stopPdu: '2F,E0,DA,03,00',
        waitMs: 150, // short duration for test speed
      );
      final link = _FakeUdsLink();
      final executor = TypedServiceStepExecutor(
        link: link,
        allowPhysicalExecution: true,
      );

      final result = await executor.executeStep(step);
      expect(result.state, StepExecutionState.completed);
      expect(link.sentRequests.length, 2);
      expect(link.sentRequests[0], [0x2F, 0xE0, 0xDA, 0x03, 0x01]); // request
      expect(link.sentRequests[1], [0x2F, 0xE0, 0xDA, 0x03, 0x00]); // cleanup stop
    });

    test('Pump-hold step executes stop PDU immediately upon cancellation', () async {
      const step = BiketuneServiceStep(
        id: 105,
        functionPk: 1,
        stepOrder: 1,
        kind: 'pump-hold',
        requestPdu: '2F,E0,DA,03,01',
        stopPdu: '2F,E0,DA,03,00',
        waitMs: 2000,
      );
      final link = _FakeUdsLink();
      final executor = TypedServiceStepExecutor(
        link: link,
        allowPhysicalExecution: true,
      );

      // Cancel shortly after start
      Future.delayed(const Duration(milliseconds: 50), () => executor.cancel());

      final result = await executor.executeStep(step);
      expect(result.state, StepExecutionState.cancelled);
      // Ensure stop PDU was sent as part of cleanup
      expect(link.sentRequests.any((r) => r.length == 5 && r[4] == 0x00), isTrue);
    });

    test('Negative response triggers stop cleanup and fails cleanly', () async {
      const step = BiketuneServiceStep(
        id: 106,
        functionPk: 1,
        stepOrder: 1,
        kind: 'routine',
        requestPdu: '31,01,F3,00',
        positiveResponse: '71',
        stopPdu: '31,02,F3,00',
      );
      final link = _FakeUdsLink();
      link.nextReply = [0x7F, 0x31, 0x22]; // NRC ConditionsNotCorrect

      final executor = TypedServiceStepExecutor(
        link: link,
        allowPhysicalExecution: true,
      );

      final result = await executor.executeStep(step);
      expect(result.state, StepExecutionState.failed);
      expect(link.sentRequests.length, 2); // request + cleanup stop
      expect(link.sentRequests[1], [0x31, 0x02, 0xF3, 0x00]);
    });
  });
}
