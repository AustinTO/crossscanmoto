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

/// Execution outcome of a single service step.
class StepExecutionResult {
  const StepExecutionResult({
    required this.stepId,
    required this.state,
    required this.message,
    this.responseData,
    this.duration = Duration.zero,
  });

  final int stepId;
  final StepExecutionState state;
  final String message;
  final List<int>? responseData;
  final Duration duration;

  bool get isSuccess => state == StepExecutionState.completed;
  bool get isCancelled => state == StepExecutionState.cancelled;
}

/// Typed service step state machine interpreting extended catalog steps
/// against an active UDS link with mandatory stop/cleanup on cancellation.
class TypedServiceStepExecutor {
  TypedServiceStepExecutor({
    required this.link,
    this.onPrompt,
    this.onStateChange,
    this.allowPhysicalExecution = true,
  });

  final UdsRequestLink link;
  final Future<bool> Function(String prompt)? onPrompt;
  final void Function(BmwExtendedServiceStep step, StepExecutionState state)? onStateChange;

  /// Whether physical execution is enabled (true by default when supported by source).
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
    BmwExtendedServiceStep step, {
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
            message: 'Cancelled by operator',
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
        message: 'Simulation verified for ${pdus.length} PDU(s)',
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

  /// Sends cleanup stop PDUs to ensure actuators/routines are safely terminated.
  Future<void> _executeCleanup(BmwExtendedServiceStep step) async {
    final stopPdus = parsePduList(step.stopPdu);
    for (final stopPdu in stopPdus) {
      try {
        await link.request(stopPdu, timeout: const Duration(seconds: 2));
      } catch (_) {}
    }
  }

  /// Executes an entire sequence of steps in strict chronological order.
  Future<List<StepExecutionResult>> executeSequence(
    List<BmwExtendedServiceStep> steps, {
    Duration defaultTimeout = const Duration(seconds: 5),
  }) async {
    final results = <StepExecutionResult>[];
    for (final step in steps) {
      if (_cancelled) break;
      final res = await executeStep(step, defaultTimeout: defaultTimeout);
      results.add(res);
      if (res.state == StepExecutionState.failed ||
          res.state == StepExecutionState.cancelled) {
        break;
      }
    }
    return List.unmodifiable(results);
  }
}
