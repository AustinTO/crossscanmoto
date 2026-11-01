import 'dart:convert';

enum AdapterRelayState { listening, authenticating, connected, stopped }

/// App-wide exclusivity signal for direct adapter connections.
class AdapterRelayCoordinator {
  AdapterRelayCoordinator._();

  static bool _hosting = false;
  static final Set<void Function()> _listeners = {};

  static bool get isHosting => _hosting;

  static set isHosting(bool next) {
    if (_hosting == next) return;
    _hosting = next;
    for (final listener in List<void Function()>.of(_listeners)) {
      listener();
    }
  }

  static void addListener(void Function() listener) => _listeners.add(listener);

  static void removeListener(void Function() listener) =>
      _listeners.remove(listener);
}

class AdapterRelayInfo {
  const AdapterRelayInfo({
    required this.addresses,
    required this.port,
    required this.token,
  });

  final List<String> addresses;
  final int port;

  /// Secret credential. Never log this value; only show/copy it on explicit
  /// user action in the relay host UI.
  final String token;
}

class RelayHandshakeLine {
  const RelayHandshakeLine(this.line, this.trailingBytes);

  final String line;
  final List<int> trailingBytes;
}

abstract final class AdapterRelayProtocol {
  static const int maximumHandshakeBytes = 128;
  static const Duration handshakeTimeout = Duration(seconds: 5);
  static const int maximumFailedAuthentications = 3;

  static List<int> clientRequest(String token) {
    if (token.isEmpty ||
        token.length > maximumHandshakeBytes - 9 ||
        token.contains(RegExp(r'[\r\n\x00-\x20]'))) {
      throw ArgumentError.value(token, 'token', 'Invalid relay token');
    }
    return ascii.encode('RELAY/1 $token\n');
  }

  static bool authenticate(String line, String expectedToken) {
    const prefix = 'RELAY/1 ';
    if (!line.startsWith(prefix)) return false;
    final provided = ascii.encode(line.substring(prefix.length));
    final expected = ascii.encode(expectedToken);
    if (provided.length != expected.length) return false;
    var difference = 0;
    for (var i = 0; i < provided.length; i++) {
      difference |= provided[i] ^ expected[i];
    }
    return difference == 0;
  }

  static RelayHandshakeLine parseLine(List<int> input) {
    final newline = input.indexOf(10);
    if (newline < 0)
      throw const FormatException('Relay handshake is incomplete');
    if (newline > maximumHandshakeBytes) {
      throw const FormatException('Relay handshake exceeds the size limit');
    }
    final lineBytes = input.sublist(0, newline);
    if (lineBytes.isNotEmpty && lineBytes.last == 13) lineBytes.removeLast();
    if (lineBytes.any((byte) => byte < 0x20 || byte > 0x7e)) {
      throw const FormatException('Relay handshake must be printable ASCII');
    }
    return RelayHandshakeLine(
      ascii.decode(lineBytes),
      List.unmodifiable(input.skip(newline + 1)),
    );
  }
}
