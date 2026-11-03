import 'dart:async';

import 'source_qualified_catalog.dart';
import 'uds_client.dart';

/// State of a typed service step execution.
enum StepExecutionState {
  idle,
  prompting,
  executing,
  dwelling,
  holding,
  completed,
  cancelled,
  failed,
  unsupported,
}

/// Result of executing an individual service step.
class StepExecutionResult {
  const StepExecutionResult({
    required this.stepId,
    required this.state,
    this.message,
    this.responseData,
    this.duration = Duration.zero,
  });

  final int stepId;
  final StepExecutionState state;
  final String? message;
  final List<int>? responseData;
  final Duration duration;

  bool get isSuccess => state == StepExecutionState.completed;
  bool get isCancelled => state == StepExecutionState.cancelled;
}

/// Typed service step state machine interpreting Biketune catalog steps
/// safely against an abstract UDS link with mandatory stop/cleanup on cancellation.
class TypedServiceStepExecutor {
  TypedServiceStepExecutor({
    required this.link,
    this.onPrompt,
    this.onStateChange,
    this.allowPhysicalExecution = false,
  });

  final UdsRequestLink link;
  final Future<bool> Function(String prompt)? onPrompt;
  final void Function(BiketuneServiceStep step, StepExecutionState state)? onStateChange;

  /// Physical execution safety gate: Must remain false unless operating in a certified bench lab.
  final bool allowPhysicalExecution;

  bool _cancelled = false;
  bool get isCancelled => _cancelled;

  void cancel() {
    _cancelled = true;
  }

  /// Parses comma- or pipe-separated hex strings into list of byte requests.
  static List<List<int>> parsePduList(String? raw) {
    if (raw == null || raw.trim().isEmpty) return const [];
    final commands = raw.contains('|') ? raw.split('|') : [raw];
    final result = <List<int>>[];

    for (final cmd in commands) {
      final trimmed = cmd.trim();
      if (trimmed.isEmpty) continue;
      // Reject raw uncompiled EDIABAS job scripts
      if (trimmed.contains('::')) continue;

      final hexTokens = trimmed.contains(',')
          ? trimmed.split(',')
          : trimmed.split(RegExp(r'\s+'));

      final bytes = <int>[];
      for (final t in hexTokens) {
        final tokenTrimmed = t.trim();
        if (tokenTrimmed.isEmpty) continue;
        final b = int.tryParse(tokenTrimmed, radix: 16);
        if (b != null) bytes.add(b);
      }
      if (bytes.isNotEmpty) {
        result.add(List.unmodifiable(bytes));
      }
    }
    return List.unmodifiable(result);
  }

  /// Executes a single typed service step with deterministic transitions, bounded delays,
  /// and guaranteed cleanup.
  Future<StepExecutionResult> executeStep(
    BiketuneServiceStep step, {
    Duration defaultTimeout = const Duration(seconds: 5),
  }) async {
    _cancelled = false;
    final stopwatch = Stopwatch()..start();

    void updateState(StepExecutionState st) {
      onStateChange?.call(step, st);
    }

    // 1. Info / prompt steps
    if (step.kind == 'info' ||
        step.kind == 'teach-throttle-open' ||
        step.kind == 'teach-throttle-close') {
      updateState(StepExecutionState.prompting);
      final text = step.text ?? 'Step ${step.stepOrder}: Proceed with operation?';

      if (onPrompt != null) {
        final accepted = await onPrompt!(text);
        if (!accepted) {
          updateState(StepExecutionState.cancelled);
          return StepExecutionResult(
            stepId: step.id,
            state: StepExecutionState.cancelled,
            message: 'User declined prompt: $text',
            duration: stopwatch.elapsed,
          );
        }
      }
      updateState(StepExecutionState.completed);
      return StepExecutionResult(
        stepId: step.id,
        state: StepExecutionState.completed,
        message: 'Prompt acknowledged',
        duration: stopwatch.elapsed,
      );
    }

    // 2. Power cycle steps
    if (step.kind == 'power-cycle') {
      updateState(StepExecutionState.dwelling);
      final waitMs = step.waitMs > 0 ? step.waitMs : 10000;
      final promptText = step.text ??
          'Turn ignition OFF, wait ${(waitMs / 1000).round()}s, then turn ignition back ON.';

      if (onPrompt != null) {
        final confirmed = await onPrompt!(promptText);
        if (!confirmed) {
          updateState(StepExecutionState.cancelled);
          return StepExecutionResult(
            stepId: step.id,
            state: StepExecutionState.cancelled,
            message: 'Power cycle cancelled by operator',
            duration: stopwatch.elapsed,
          );
        }
      }
      updateState(StepExecutionState.completed);
      return StepExecutionResult(
        stepId: step.id,
        state: StepExecutionState.completed,
        message: 'Power cycle completed',
        duration: stopwatch.elapsed,
      );
    }

    // 3. Executable PDU validation
    final pdus = parsePduList(step.requestPdu);
    if (pdus.isEmpty) {
      updateState(StepExecutionState.unsupported);
      return StepExecutionResult(
        stepId: step.id,
        state: StepExecutionState.unsupported,
        message: 'Step has no executable UDS PDU or contains uncompiled EDIABAS job: ${step.text}',
        duration: stopwatch.elapsed,
      );
    }

    if (!allowPhysicalExecution) {
      updateState(StepExecutionState.completed);
      return StepExecutionResult(
        stepId: step.id,
        state: StepExecutionState.completed,
        message: 'Simulated execution verified for ${pdus.length} PDU(s) (Physical execution safe-gated)',
        duration: stopwatch.elapsed,
      );
    }

    // 4. Executing request PDUs
    updateState(StepExecutionState.executing);
    List<int>? lastResponse;

    try {
      for (final pdu in pdus) {
        if (_cancelled) {
          await _executeCleanup(step);
          updateState(StepExecutionState.cancelled);
          return StepExecutionResult(
            stepId: step.id,
            state: StepExecutionState.cancelled,
            message: 'Execution cancelled before sending PDU',
            duration: stopwatch.elapsed,
          );
        }

        final reply = await link.request(pdu, timeout: defaultTimeout);
        lastResponse = reply;

        // Verify positive response if expected
        if (step.positiveResponse != null && step.positiveResponse!.isNotEmpty) {
          final expectedPos = int.tryParse(step.positiveResponse!.trim(), radix: 16);
          if (expectedPos != null && reply.isNotEmpty && reply.first != expectedPos) {
            await _executeCleanup(step);
            updateState(StepExecutionState.failed);
            return StepExecutionResult(
              stepId: step.id,
              state: StepExecutionState.failed,
              message: 'Negative or mismatched response: expected 0x${expectedPos.toRadixString(16)}, got ${reply.isEmpty ? "empty" : "0x" + reply.first.toRadixString(16)}',
              responseData: reply,
              duration: stopwatch.elapsed,
            );
          }
        }
      }

      // 5. Holding / Dwell phase (e.g. ABS pump hold)
      if (step.kind == 'pump-hold' && step.waitMs > 0) {
        updateState(StepExecutionState.holding);
        final holdEnd = DateTime.now().add(Duration(milliseconds: step.waitMs));

        while (DateTime.now().isBefore(holdEnd)) {
          if (_cancelled) {
            await _executeCleanup(step);
            updateState(StepExecutionState.cancelled);
            return StepExecutionResult(
              stepId: step.id,
              state: StepExecutionState.cancelled,
              message: 'Pump hold cancelled early',
              duration: stopwatch.elapsed,
            );
          }
          await Future<void>.delayed(const Duration(milliseconds: 100));
        }

        // Send mandatory stop PDU after hold completes
        await _executeCleanup(step);
      }

      updateState(StepExecutionState.completed);
      return StepExecutionResult(
        stepId: step.id,
        state: StepExecutionState.completed,
        message: 'Step completed successfully',
        responseData: lastResponse,
        duration: stopwatch.elapsed,
      );
    } catch (e) {
      await _executeCleanup(step);
      updateState(StepExecutionState.failed);
      return StepExecutionResult(
        stepId: step.id,
        state: StepExecutionState.failed,
        message: 'Exception during step execution: $e',
        duration: stopwatch.elapsed,
      );
    }
  }

  /// Sends stop PDU(s) to guarantee actuators/pumps are safely deactivated.
  Future<void> _executeCleanup(BiketuneServiceStep step) async {
    if (step.stopPdu == null || step.stopPdu!.isEmpty) return;
    final stopPdus = parsePduList(step.stopPdu);
    for (final stop in stopPdus) {
      try {
        await link.request(stop, timeout: const Duration(seconds: 2));
      } catch (_) {
        // Suppress cleanup secondary errors to guarantee exit
      }
    }
  }
}
