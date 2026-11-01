import 'dart:async';
import 'dart:io';

import 'adapter_relay_types.dart';
import 'elm_session.dart';

/// iOS/native client for an Android-hosted RFCOMM-to-TCP relay.
class RelayAdapterTransport implements AdapterTransport {
  RelayAdapterTransport._(this._socket, this._reader) {
    _incoming = StreamController<List<int>>(
      onListen: () => unawaited(_pumpIncoming()),
    );
  }

  final Socket _socket;
  final _RelayClientReader _reader;
  late final StreamController<List<int>> _incoming;
  bool _closed = false;

  static Future<RelayAdapterTransport> connect(
    String host,
    int port,
    String token, {
    Duration timeout = AdapterRelayProtocol.handshakeTimeout,
  }) async {
    if (host.trim().isEmpty) throw ArgumentError.value(host, 'host');
    if (port < 1 || port > 65535) {
      throw RangeError.range(port, 1, 65535, 'port');
    }
    final request = AdapterRelayProtocol.clientRequest(token);
    final socket = await Socket.connect(host.trim(), port, timeout: timeout);
    final reader = _RelayClientReader(socket);
    try {
      socket.add(request);
      await socket.flush().timeout(timeout);
      final response = await reader.readLine(timeout: timeout).timeout(timeout);
      if (response.line != 'OK') {
        throw const FormatException('Relay authentication was rejected');
      }
      return RelayAdapterTransport._(socket, reader);
    } catch (_) {
      await reader.cancel();
      socket.destroy();
      rethrow;
    }
  }

  @override
  Stream<List<int>> get incoming => _incoming.stream;

  @override
  Future<void> write(List<int> bytes) async {
    if (_closed) throw StateError('Relay transport is closed');
    _socket.add(bytes);
    await _socket.flush();
  }

  Future<void> _pumpIncoming() async {
    try {
      await for (final bytes in _reader.remaining()) {
        if (_closed) return;
        if (bytes.isNotEmpty) _incoming.add(bytes);
      }
    } catch (error, stack) {
      if (!_closed) _incoming.addError(error, stack);
    } finally {
      if (!_incoming.isClosed) await _incoming.close();
    }
  }

  @override
  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    await _reader.cancel();
    _socket.destroy();
    if (!_incoming.isClosed) unawaited(_incoming.close());
  }
}

class _RelayClientReader {
  _RelayClientReader(Socket socket) : _iterator = StreamIterator(socket);

  final StreamIterator<List<int>> _iterator;
  final List<int> _buffer = [];
  bool _remainingStarted = false;

  Future<RelayHandshakeLine> readLine({required Duration timeout}) async {
    while (true) {
      final newline = _buffer.indexOf(10);
      if (newline >= 0) {
        if (newline > AdapterRelayProtocol.maximumHandshakeBytes) {
          throw const FormatException('Relay response exceeds the size limit');
        }
        final lineAndTail = _buffer.sublist(0, newline + 1);
        final trailing = _buffer.sublist(newline + 1);
        final parsed = AdapterRelayProtocol.parseLine(lineAndTail);
        _buffer
          ..clear()
          ..addAll(trailing);
        return parsed;
      }
      if (_buffer.length > AdapterRelayProtocol.maximumHandshakeBytes) {
        throw const FormatException('Relay response exceeds the size limit');
      }
      if (!await _iterator.moveNext().timeout(timeout)) {
        throw const SocketException(
            'Relay closed before authentication response');
      }
      _buffer.addAll(_iterator.current);
    }
  }

  Stream<List<int>> remaining() async* {
    if (_remainingStarted) return;
    _remainingStarted = true;
    if (_buffer.isNotEmpty) {
      yield List.unmodifiable(_buffer);
      _buffer.clear();
    }
    while (await _iterator.moveNext()) {
      yield List.unmodifiable(_iterator.current);
    }
  }

  Future<void> cancel() => _iterator.cancel();
}
