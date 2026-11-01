import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import '../lib/diagnostics/adapter_relay_io.dart';
import '../lib/diagnostics/adapter_relay_types.dart';
import '../lib/diagnostics/elm_session.dart';
import '../lib/diagnostics/relay_connect.dart';

class FakeBluetoothTransport implements AdapterTransport {
  final _incoming = StreamController<List<int>>.broadcast();
  final writes = <List<int>>[];
  final firstWrite = Completer<List<int>>();
  bool closed = false;

  @override
  Stream<List<int>> get incoming => _incoming.stream;

  @override
  Future<void> write(List<int> bytes) async {
    final copy = List<int>.unmodifiable(bytes);
    writes.add(copy);
    if (!firstWrite.isCompleted) firstWrite.complete(copy);
    _incoming.add([0xe1, ...copy]);
  }

  void respond(List<int> bytes) => _incoming.add(bytes);

  @override
  Future<void> close() async {
    if (closed) return;
    closed = true;
    await _incoming.close();
  }
}

void check(bool value, String message) {
  if (!value) throw StateError(message);
}

Future<List<int>> _readOneLine(Socket socket) async {
  final iterator = StreamIterator<List<int>>(socket);
  final bytes = <int>[];
  try {
    while (await iterator.moveNext().timeout(const Duration(seconds: 2))) {
      bytes.addAll(iterator.current);
      final newline = bytes.indexOf(10);
      if (newline >= 0) return bytes.sublist(0, newline + 1);
    }
  } finally {
    await iterator.cancel();
  }
  throw const SocketException('Expected a line from relay server');
}

Future<bool> _loopbackSocketsAvailable() async {
  try {
    final probe = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    await probe.close();
    return true;
  } on SocketException {
    return false;
  }
}

Future<void> runAdapterRelayChecks({bool requireLoopback = false}) async {
  check(
    AdapterRelayProtocol.authenticate('RELAY/1 secret', 'secret'),
    'Valid relay token rejected',
  );
  check(
    !AdapterRelayProtocol.authenticate('RELAY/1 secretX', 'secret'),
    'Incorrect relay token accepted',
  );
  check(
    AdapterRelayProtocol.parseLine(ascii.encode('OK\nxyz'))
            .trailingBytes
            .join(',') ==
        '120,121,122',
    'Handshake parser lost trailing bytes',
  );
  for (final bytes in <List<int>>[
    ascii.encode('RELAY/1 incomplete'),
    [
      ...List<int>.filled(AdapterRelayProtocol.maximumHandshakeBytes + 1, 65),
      10
    ],
  ]) {
    try {
      AdapterRelayProtocol.parseLine(bytes);
      throw StateError('Incomplete or oversized auth line accepted');
    } on FormatException {
      // The parser requires a newline and enforces its line length bound.
    }
  }

  if (!await _loopbackSocketsAvailable()) {
    if (requireLoopback) {
      throw const SocketException(
        'Loopback sockets are unavailable; relay transport checks did not run.',
      );
    }
    // ignore: avoid_print
    print(
        'PASS: relay authentication parser; SKIP loopback integration (sockets unavailable)');
    return;
  }

  final fakeBluetooth = FakeBluetoothTransport();
  final server = await AdapterRelayServer.forTesting(
    fakeBluetooth,
    random: Random(7),
  );
  check(server.info.port > 0, 'Relay did not bind an ephemeral port');
  check(server.info.token.length == 22, 'Relay token is not 128-bit base64url');
  check(AdapterRelayCoordinator.isHosting,
      'Global relay-exclusive flag was not set');

  final client = await RelayAdapterTransport.connect(
    '127.0.0.1',
    server.info.port,
    server.info.token,
  );
  final response = Completer<List<int>>();
  final clientSubscription = client.incoming.listen((bytes) {
    if (!response.isCompleted) response.complete(bytes);
  });
  await client.write([0x41, 0x54, 0x49]);
  check((await fakeBluetooth.firstWrite.future).join(',') == '65,84,73',
      'Authenticated bytes did not reach the Bluetooth adapter');
  check(
      (await response.future.timeout(const Duration(seconds: 2))).join(',') ==
          '225,65,84,73',
      'Bluetooth response bytes did not reach the client');

  final secondClient = await Socket.connect('127.0.0.1', server.info.port);
  secondClient.add(AdapterRelayProtocol.clientRequest(server.info.token));
  await secondClient.flush();
  final busy = await _readOneLine(secondClient);
  check(ascii.decode(busy).trim() == 'ERR busy',
      'Second client was not rejected');
  secondClient.destroy();

  await clientSubscription.cancel();
  await client.close();
  await Future<void>.delayed(const Duration(milliseconds: 30));
  check(!server.isRunning, 'Client disconnect did not stop the relay');
  check(fakeBluetooth.closed, 'Client disconnect left Bluetooth open');
  check(!AdapterRelayCoordinator.isHosting,
      'Global relay-exclusive flag remained set after teardown');

  final samePacketBluetooth = FakeBluetoothTransport();
  final samePacketServer =
      await AdapterRelayServer.forTesting(samePacketBluetooth);
  final samePacketSocket =
      await Socket.connect('127.0.0.1', samePacketServer.info.port);
  samePacketSocket.add([
    ...AdapterRelayProtocol.clientRequest(samePacketServer.info.token),
    0x55,
    0x66,
  ]);
  await samePacketSocket.flush();
  check(ascii.decode(await _readOneLine(samePacketSocket)).trim() == 'OK',
      'Same-packet client handshake was rejected');
  check((await samePacketBluetooth.firstWrite.future).join(',') == '85,102',
      'Bytes following the request line were not forwarded after auth');
  samePacketSocket.destroy();
  await Future<void>.delayed(const Duration(milliseconds: 30));
  check(samePacketBluetooth.closed,
      'Same-packet client disconnect did not close the adapter');

  final unauthenticatedBluetooth = FakeBluetoothTransport();
  final unauthenticatedServer = await AdapterRelayServer.forTesting(
    unauthenticatedBluetooth,
  );
  final unauthenticatedClient =
      await Socket.connect('127.0.0.1', unauthenticatedServer.info.port);
  unauthenticatedClient.add(ascii.encode('RELAY/1 wrong-token\nEARLY'));
  await unauthenticatedClient.flush();
  final rejected = await _readOneLine(unauthenticatedClient);
  check(ascii.decode(rejected).trim() == 'ERR auth',
      'Bad token did not receive an auth rejection');
  check(unauthenticatedBluetooth.writes.isEmpty,
      'Bytes before authentication reached Bluetooth');
  unauthenticatedClient.destroy();
  await unauthenticatedServer.stop();
  check(unauthenticatedBluetooth.closed,
      'Explicit stop did not close the Bluetooth transport');

  final pendingAuthBluetooth = FakeBluetoothTransport();
  final pendingAuthServer =
      await AdapterRelayServer.forTesting(pendingAuthBluetooth);
  final pendingAuthSocket =
      await Socket.connect('127.0.0.1', pendingAuthServer.info.port);
  await Future<void>.delayed(const Duration(milliseconds: 20));
  await pendingAuthServer.stop();
  check(pendingAuthBluetooth.closed,
      'Stopping during authentication did not close Bluetooth');
  try {
    await _readOneLine(pendingAuthSocket);
    throw StateError('Pending unauthenticated socket was not destroyed');
  } on SocketException {
    // Expected: stopping the host destroys unauthenticated clients too.
  }
  pendingAuthSocket.destroy();

  final timeoutBluetooth = FakeBluetoothTransport();
  final timeoutServer = await AdapterRelayServer.forTesting(
    timeoutBluetooth,
    handshakeTimeout: const Duration(milliseconds: 50),
  );
  final timeoutSocket =
      await Socket.connect('127.0.0.1', timeoutServer.info.port);
  timeoutSocket.add(ascii.encode('RELAY/1 partial'));
  await timeoutSocket.flush();
  check(ascii.decode(await _readOneLine(timeoutSocket)).trim() == 'ERR auth',
      'Incomplete handshake did not time out');
  check(timeoutServer.isRunning && timeoutBluetooth.writes.isEmpty,
      'Handshake timeout left the server stuck or wrote to Bluetooth');
  timeoutSocket.destroy();
  await timeoutServer.stop();

  // A single server write deliberately combines the auth line and stream
  // bytes. The relay client must preserve the bytes after the newline.
  final testServer = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
  final serverDone = Completer<void>();
  testServer.listen((socket) async {
    final line = await _readOneLine(socket);
    check(ascii.decode(line).trim() == 'RELAY/1 client-token',
        'Client handshake was malformed');
    socket.add([
      ...ascii.encode('OK\n'),
      0xde,
      0xad,
    ]);
    await socket.flush();
    serverDone.complete();
    await socket.close();
  });
  final clientWithTrailing = await RelayAdapterTransport.connect(
    '127.0.0.1',
    testServer.port,
    'client-token',
  );
  final trailing = Completer<List<int>>();
  final trailingSubscription = clientWithTrailing.incoming.listen((bytes) {
    if (!trailing.isCompleted) trailing.complete(bytes);
  });
  check(
      (await trailing.future.timeout(const Duration(seconds: 2))).join(',') ==
          '222,173',
      'Client discarded bytes following the auth response');
  await serverDone.future.timeout(const Duration(seconds: 2));
  await trailingSubscription.cancel();
  await clientWithTrailing.close();
  await testServer.close();

  // ignore: avoid_print
  print(
      'PASS: relay auth ordering, raw byte forwarding, exclusivity, trailing bytes and lifecycle');
}

Future<void> main() async {
  await runAdapterRelayChecks();
  exit(0);
}
