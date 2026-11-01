import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'adapter_relay_types.dart';
import 'elm_session.dart';

/// Android-side, single-client raw byte relay for an already paired RFCOMM
/// adapter. The relay never creates an ElmSession on the host side.
class AdapterRelayServer {
  AdapterRelayServer._(
    this._bluetooth,
    Random random, {
    Duration handshakeTimeout = AdapterRelayProtocol.handshakeTimeout,
  })  : _token = _newToken(random),
        _handshakeTimeout = handshakeTimeout;

  final AdapterTransport _bluetooth;
  final String _token;
  final Duration _handshakeTimeout;
  final StreamController<AdapterRelayState> _states =
      StreamController<AdapterRelayState>.broadcast();

  ServerSocket? _server;
  Socket? _client;
  _SocketByteReader? _clientReader;
  Socket? _authSocket;
  _SocketByteReader? _authReader;
  StreamSubscription<List<int>>? _bluetoothSubscription;
  Future<void> _bluetoothWrites = Future<void>.value();
  AdapterRelayState _state = AdapterRelayState.stopped;
  int _failedAuthentications = 0;
  bool _authInProgress = false;
  bool _stopping = false;
  late final AdapterRelayInfo _info;

  AdapterRelayInfo get info => _info;
  AdapterRelayState get state => _state;
  Stream<AdapterRelayState> get stateChanges => _states.stream;
  bool get isRunning => _server != null && !_stopping;

  static Future<AdapterRelayServer> start({
    required bool diagnosticSessionConnected,
    required Future<AdapterTransport> Function() connectBluetooth,
    int port = 0,
  }) async {
    if (diagnosticSessionConnected) {
      throw StateError(
        'Disconnect the active adapter session before starting a relay.',
      );
    }
    if (AdapterRelayCoordinator.isHosting) {
      throw StateError('An adapter relay is already active.');
    }

    AdapterRelayCoordinator.isHosting = true;
    AdapterTransport? bluetooth;
    AdapterRelayServer? relay;
    try {
      bluetooth = await connectBluetooth();
      relay = AdapterRelayServer._(bluetooth, Random.secure());
      await relay._bind(port);
      return relay;
    } catch (_) {
      if (relay != null) {
        await relay.stop();
      } else {
        await bluetooth?.close();
        AdapterRelayCoordinator.isHosting = false;
      }
      rethrow;
    }
  }

  /// Loopback integration-test constructor. Production hosts must use [start]
  /// so paired-device selection and the active-session guard are enforced.
  static Future<AdapterRelayServer> forTesting(
    AdapterTransport bluetooth, {
    int port = 0,
    Random? random,
    Duration handshakeTimeout = AdapterRelayProtocol.handshakeTimeout,
  }) async {
    if (AdapterRelayCoordinator.isHosting) {
      throw StateError('An adapter relay is already active.');
    }
    AdapterRelayCoordinator.isHosting = true;
    final relay = AdapterRelayServer._(
      bluetooth,
      random ?? Random.secure(),
      handshakeTimeout: handshakeTimeout,
    );
    try {
      await relay._bind(port);
      return relay;
    } catch (_) {
      await relay.stop();
      rethrow;
    }
  }

  Future<void> _bind(int port) async {
    if (port < 0 || port > 65535) {
      throw RangeError.range(port, 0, 65535, 'port');
    }
    _server = await ServerSocket.bind(InternetAddress.anyIPv4, port);
    final bound = _server!;
    _setState(AdapterRelayState.listening);
    bound.listen(
      (socket) => unawaited(_accept(socket)),
      onError: (_) => unawaited(stop()),
      onDone: () => unawaited(stop()),
      cancelOnError: true,
    );
    _info = AdapterRelayInfo(
      addresses: List.unmodifiable(await _localIpv4Addresses()),
      port: bound.port,
      token: _token,
    );
  }

  Future<void> _accept(Socket socket) async {
    if (_stopping) {
      socket.destroy();
      return;
    }
    if (_client != null || _authInProgress) {
      await _reject(socket, 'ERR busy\n');
      return;
    }

    _authInProgress = true;
    _authSocket = socket;
    _setState(AdapterRelayState.authenticating);
    final reader = _SocketByteReader(socket);
    _authReader = reader;
    try {
      final request = await reader
          .readLine(timeout: _handshakeTimeout)
          .timeout(_handshakeTimeout);
      if (!AdapterRelayProtocol.authenticate(request.line, _token)) {
        await _authenticationFailed(socket, reader);
        return;
      }

      // Authentication has completed before any bytes are written to Bluetooth.
      _client = socket;
      _clientReader = reader;
      _authSocket = null;
      _authReader = null;
      _authInProgress = false;
      _failedAuthentications = 0;
      _setState(AdapterRelayState.connected);
      socket.add(ascii.encode('OK\n'));
      await socket.flush();

      _bluetoothSubscription = _bluetooth.incoming.listen(
        (bytes) {
          final activeSocket = _client;
          if (activeSocket == null || _stopping) return;
          _bluetoothWrites = _bluetoothWrites.then((_) async {
            activeSocket.add(bytes);
            await activeSocket.flush();
          }).catchError((Object _) {
            unawaited(stop());
          });
        },
        onError: (_) => unawaited(stop()),
        onDone: () => unawaited(stop()),
      );
      unawaited(_forwardClientToBluetooth(reader));
    } catch (_) {
      if (_client == null && !_stopping) {
        await _authenticationFailed(socket, reader);
      } else {
        await stop();
      }
    }
  }

  Future<void> _forwardClientToBluetooth(_SocketByteReader reader) async {
    try {
      await for (final bytes in reader.remaining()) {
        if (_stopping) return;
        if (bytes.isNotEmpty) await _bluetooth.write(bytes);
      }
    } catch (_) {
      // Closing either end closes the whole relay and the RFCOMM transport.
    }
    await stop();
  }

  Future<void> _authenticationFailed(
    Socket socket,
    _SocketByteReader reader,
  ) async {
    _authInProgress = false;
    if (identical(_authSocket, socket)) {
      _authSocket = null;
      _authReader = null;
    }
    _failedAuthentications++;
    _setState(AdapterRelayState.listening);
    await _reject(socket, 'ERR auth\n', reader: reader);
    if (_failedAuthentications >=
        AdapterRelayProtocol.maximumFailedAuthentications) {
      await stop();
    }
  }

  Future<void> _reject(Socket socket, String message,
      {_SocketByteReader? reader}) async {
    try {
      socket.add(ascii.encode(message));
      await socket.flush().timeout(const Duration(milliseconds: 250));
    } catch (_) {
      // The peer may already have closed.
    }
    await reader?.cancel();
    socket.destroy();
  }

  Future<void> stop() async {
    if (_stopping) return;
    _stopping = true;
    _setState(AdapterRelayState.stopped);
    final server = _server;
    _server = null;
    await server?.close();
    await _bluetoothSubscription?.cancel();
    _bluetoothSubscription = null;
    _client?.destroy();
    _client = null;
    await _clientReader?.cancel();
    _clientReader = null;
    _authSocket?.destroy();
    _authSocket = null;
    await _authReader?.cancel();
    _authReader = null;
    try {
      await _bluetooth.close();
    } catch (_) {
      // Relay teardown is best effort across both transports.
    }
    AdapterRelayCoordinator.isHosting = false;
    await _states.close();
  }

  void _setState(AdapterRelayState state) {
    _state = state;
    if (!_states.isClosed) _states.add(state);
  }

  static String _newToken(Random random) => base64Url
      .encode(List<int>.generate(16, (_) => random.nextInt(256)))
      .replaceAll('=', '');

  static Future<List<String>> _localIpv4Addresses() async {
    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLoopback: false,
      );
      final addresses = interfaces
          .expand((interface) => interface.addresses)
          .where((address) => !address.isLoopback)
          .map((address) => address.address)
          .toSet()
          .toList(growable: false);
      if (addresses.isNotEmpty) return addresses;
    } catch (_) {
      // A loopback address is useful for local testing when no LAN is active.
    }
    return const ['127.0.0.1'];
  }
}

class _SocketByteReader {
  _SocketByteReader(Socket socket) : _iterator = StreamIterator(socket);

  final StreamIterator<List<int>> _iterator;
  final List<int> _buffer = [];
  bool _remainingStarted = false;

  Future<RelayHandshakeLine> readLine({required Duration timeout}) async {
    while (true) {
      final newline = _buffer.indexOf(10);
      if (newline >= 0) {
        if (newline > AdapterRelayProtocol.maximumHandshakeBytes) {
          throw const FormatException('Relay handshake exceeds the size limit');
        }
        final line = _buffer.sublist(0, newline + 1);
        final trailing = _buffer.sublist(newline + 1);
        _buffer
          ..clear()
          ..addAll(line);
        final parsed = AdapterRelayProtocol.parseLine(_buffer);
        _buffer
          ..clear()
          ..addAll(trailing);
        return parsed;
      }
      if (_buffer.length > AdapterRelayProtocol.maximumHandshakeBytes) {
        throw const FormatException('Relay handshake exceeds the size limit');
      }
      if (!await _iterator.moveNext().timeout(timeout)) {
        throw const SocketException('Peer closed before relay handshake');
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
