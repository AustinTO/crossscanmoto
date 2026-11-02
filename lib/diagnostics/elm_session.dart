import 'dart:async';
import 'dart:convert';

/// Byte transport shared by RFCOMM and TCP adapters.
abstract interface class AdapterTransport {
  Stream<List<int>> get incoming;
  Future<void> write(List<int> bytes);
  Future<void> close();
}

class AdapterResponse {
  const AdapterResponse(this.command, this.lines);
  final String command;
  final List<String> lines;
  bool get isError => lines.any((line) => const {
        '?',
        'ERROR',
        'NO DATA',
        'STOPPED',
        'UNABLE TO CONNECT',
        'CAN ERROR',
        'BUS ERROR',
        'BUFFER FULL',
      }.contains(line.toUpperCase()));
  String get text => lines.join('\n');
}

/// ELM prompt framing. Requests are serialized because responses carry no ID.
class ElmSession {
  ElmSession(this.transport) {
    _subscription = transport.incoming.listen(_receive,
        onError: _fail,
        onDone: () => _fail(StateError('Adapter disconnected')));
  }
  final AdapterTransport transport;
  late final StreamSubscription<List<int>> _subscription;
  final StringBuffer _buffer = StringBuffer();
  Future<void> _queue = Future<void>.value();
  Completer<String>? _pending;
  final Completer<Object> _failure = Completer<Object>();
  Future<Object> get failure => _failure.future;
  bool _closed = false;
  bool _desynchronized = false;

  Future<AdapterResponse> command(String command,
      {Duration timeout = const Duration(seconds: 5)}) {
    if (command.isEmpty || command.contains(RegExp(r'[\r\n]'))) {
      return Future.error(ArgumentError('Expected one nonempty command'));
    }
    final result = Completer<AdapterResponse>();
    _queue = _queue.then((_) async {
      try {
        if (_closed || _desynchronized) {
          throw StateError('Reconnect adapter before sending another command');
        }
        final pending = Completer<String>();
        _pending = pending;
        _buffer.clear();
        final responseFuture = pending.future.timeout(timeout);
        // Install an error handler before asynchronous transport writes.
        unawaited(responseFuture.then<void>((_) {}, onError: (Object _) {}));
        await transport.write(ascii.encode('$command\r')).timeout(timeout);
        final raw = await responseFuture;
        final lines = raw
            .split(RegExp(r'[\r\n]+'))
            .map((line) => line.trim())
            .where((line) =>
                line.isNotEmpty && line.toUpperCase() != command.toUpperCase())
            .toList(growable: false);
        result.complete(AdapterResponse(command, lines));
      } catch (error, stack) {
        // A late response must never be attributed to the next request.
        _fail(error);
        result.completeError(error, stack);
      } finally {
        _pending = null;
      }
    });
    return result.future;
  }

  void _receive(List<int> bytes) {
    for (final byte in bytes) {
      if (byte == 62) {
        final pending = _pending;
        if (pending != null && !pending.isCompleted) {
          pending.complete(_buffer.toString());
        }
        _buffer.clear();
      } else if (_pending != null) {
        if (_buffer.length >= 1024 * 1024) {
          _fail(StateError('Adapter response exceeds limit'));
          return;
        }
        _buffer.writeCharCode(byte);
      }
    }
  }

  void _fail(Object error) {
    if (!_failure.isCompleted) _failure.complete(error);
    _desynchronized = true;
    final pending = _pending;
    if (pending != null && !pending.isCompleted) pending.completeError(error);
  }

  Future<void> close() async {
    _closed = true;
    _fail(StateError('Session closed'));
    await _subscription.cancel();
    await transport.close();
  }
}
