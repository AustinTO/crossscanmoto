import 'elm_session.dart';
import 'kwp_response.dart';

/// Sends one BMW motorcycle KWP application request and returns its payload.
/// Payloads exclude the ELM count/checksum bytes.
abstract interface class KwpRequestLink {
  Future<List<int>> request(List<int> payload, {Duration? timeout});

  Future<bool> startCommunication();
}

class KwpBusyException implements Exception {
  const KwpBusyException(this.service, this.retries);

  final int service;
  final int retries;

  @override
  String toString() =>
      'KWP service 0x${service.toRadixString(16).padLeft(2, '0')} '
      'remained busy after $retries retries';
}

class KwpResponsePendingException implements Exception {
  const KwpResponsePendingException(this.service);

  final int service;

  @override
  String toString() =>
      'KWP service 0x${service.toRadixString(16).padLeft(2, '0')} '
      'returned pending without a final response before the ELM prompt';
}

/// BMW Motorrad KWP2000 diagnostic transport over an ELM-compatible adapter.
///
/// Configures adapter initialization and timing for legacy K-Line BMW motorcycle ECUs.
class BmwBikeKwpLink implements KwpRequestLink {
  BmwBikeKwpLink(
    this.session, {
    this.commandTimeout = const Duration(milliseconds: 1500),
    this.maxBusyRetries = 2,
  }) {
    if (maxBusyRetries < 0) {
      throw RangeError.range(maxBusyRetries, 0, null, 'maxBusyRetries');
    }
  }

  final ElmSession session;
  final Duration commandTimeout;

  /// The 1.83 adapter recursively retried NRC 0x21 without a limit. This
  /// client caps that behavior so a permanently busy ECU cannot loop forever.
  final int maxBusyRetries;

  int? _configuredAddress;

  bool get isConfigured => _configuredAddress != null;

  /// Selects BMW motorcycle KWP (ELM protocol 5) for one ECU address.
  ///
  /// The sequence transcribes the 1.83 ELM adapter branch. Current 1.110 DEX
  /// retains these KWP-related AT literals and separately retains the same
  /// `0x81` / `0x1A80` application startup behavior; the full current setup
  /// sequence has not been claimed identical.
  Future<bool> configure({required int ecuAddress}) async {
    if (ecuAddress < 0 || ecuAddress > 0xff) {
      throw RangeError.range(ecuAddress, 0, 0xff, 'ecuAddress');
    }
    if (_configuredAddress == ecuAddress) return true;
    _configuredAddress = null;

    final address = ecuAddress.toRadixString(16).padLeft(2, '0');
    final commands = <String>[
      'ATPC',
      'ATAL',
      'ATSH81${address}F1',
      'ATWM81${address}F13E',
      'ATST50',
      'ATSP5',
    ];
    for (final command in commands) {
      final response = await session.command(command, timeout: commandTimeout);
      if (!response.lines.any((line) => line.contains('OK'))) return false;
    }

    _configuredAddress = ecuAddress;
    return true;
  }

  /// Performs the per-operation standard KWP startCommunication sequence.
  ///
  /// Sends `0x81` (StartCommunication), accepting `0xC1` or `0x5A` confirmation.
  @override
  Future<bool> startCommunication() async {
    _requireConfigured();
    final reply = await request(const [
      0x81,
    ], timeout: const Duration(seconds: 3));
    if (reply.isNotEmpty && (reply.first == 0xc1 || reply.first == 0x5a)) {
      return true;
    }
    if (!_hasNrc(reply, 0x81, 0x11) && !_hasNrc(reply, 0x81, 0x12)) {
      return false;
    }

    final probe = await request(const [
      0x1a,
      0x80,
    ], timeout: const Duration(seconds: 3));
    return probe.isNotEmpty && probe.first == 0x5a;
  }

  /// Runs the ECU discovery sequence from the 1.83 KWP branch and returns the
  /// raw `1A 80` identification response, if the ECU accepts the probe.
  Future<List<int>?> probeAndIdentify() async {
    _requireConfigured();
    final start = await request(const [
      0x81,
    ], timeout: const Duration(seconds: 4));
    final supportedByProbe =
        _hasNrc(start, 0x81, 0x11) || _hasNrc(start, 0x81, 0x12);
    if (start.isEmpty || (start.first != 0xc1 && !supportedByProbe)) {
      return null;
    }

    if (supportedByProbe) {
      final probe = await request(const [
        0x1a,
        0x80,
      ], timeout: const Duration(seconds: 2));
      if (probe.isEmpty || probe.first != 0x5a) return null;
    }

    return request(const [0x1a, 0x80], timeout: const Duration(seconds: 2));
  }

  /// Sends raw KWP bytes as contiguous hex. Each returned ELM line follows the
  /// 1.83 framing parser: byte 0 is payload length, then payload, then checksum.
  /// The old adapter did not reassemble multi-frame application responses.
  @override
  Future<List<int>> request(List<int> payload, {Duration? timeout}) async {
    _requireConfigured();
    if (payload.isEmpty || payload.any((byte) => byte < 0 || byte > 0xff)) {
      throw ArgumentError('Expected nonempty bytes in range 0..255');
    }

    final command = payload
        .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
        .join()
        .toUpperCase();
    final actualTimeout = timeout ?? const Duration(seconds: 3);

    for (var retry = 0; ; retry++) {
      final response = await session.command(command, timeout: actualTimeout);
      final frames = decodeElmResponseLines(response.lines);
      if (frames.isEmpty) {
        throw const FormatException('ELM returned no KWP response frames');
      }

      final first = frames.first;
      if (_hasNrc(first, payload.first, 0x21)) {
        if (retry >= maxBusyRetries) {
          throw KwpBusyException(payload.first, retry);
        }
        continue;
      }
      if (_hasNrc(first, payload.first, 0x78)) {
        final finalFrame = frames.skipWhile(
          (frame) => _hasNrc(frame, payload.first, 0x78),
        );
        if (finalFrame.isEmpty) {
          throw KwpResponsePendingException(payload.first);
        }
        return finalFrame.first;
      }
      return first;
    }
  }

  /// Decodes KWP response token framing from adapter line buffers.
  static List<List<int>> decodeElmResponseLines(List<String> lines) {
    final frames = <List<int>>[];
    for (var line in lines) {
      line = line
          .replaceAll('SEARCHING...', '')
          .replaceAll('BUS INIT: ...OK', '')
          .replaceAll('BUS INIT: OK', '')
          .replaceAll('>', '')
          .trim();
      if (line.isEmpty) continue;

      final upper = line.toUpperCase();
      if (upper == '?' || upper == 'NO DATA') {
        throw FormatException('ELM did not return KWP data: $line');
      }
      if (const [
        'ERROR',
        'ERR',
        'STOPPED',
        'BUS BUSY',
        'ACT ALERT',
        'BUFFER FULL',
        'UNABLE TO CONNECT',
        'LP ALERT',
        'LV RESET',
      ].any(upper.contains)) {
        throw StateError('ELM KWP request failed: $line');
      }

      var compact = line.replaceAll(RegExp(r'[ ,]'), '');
      if (compact.length.isOdd) compact = '0$compact';
      if (compact.isEmpty || !RegExp(r'^[0-9a-fA-F]+$').hasMatch(compact)) {
        throw FormatException('Malformed ELM KWP frame: $line');
      }
      final frame = <int>[];
      for (var offset = 0; offset < compact.length; offset += 2) {
        frame.add(int.parse(compact.substring(offset, offset + 2), radix: 16));
      }
      final payloadLength = frame.first;
      // Java stored the length byte as signed and could only allocate up to
      // 127 bytes in the recovered legacy KWP parser.
      if (payloadLength > 0x7f || frame.length != payloadLength + 2) {
        throw FormatException(
          'KWP ELM length byte does not match frame: $line',
        );
      }
      frames.add(List.unmodifiable(frame.skip(1).take(payloadLength)));
    }
    return List.unmodifiable(frames);
  }

  static bool _hasNrc(List<int> frame, int requestService, int code) =>
      frame.length == 3 &&
      frame[0] == 0x7f &&
      frame[1] == requestService &&
      frame[2] == code;

  void _requireConfigured() {
    if (!isConfigured) {
      throw StateError('Configure BMW motorcycle KWP before sending requests');
    }
  }
}

/// BMW Motorrad KWP2000 diagnostic client.
class KwpClient {
  KwpClient(this.link);

  final KwpRequestLink link;

  /// Reads diagnostic trouble codes via KWP Service 0x18.
  Future<KwpDtcReport> readDtc() async {
    await _startCommunication();
    final response = await _positive(0x18, const [0x02, 0xff, 0xff]);
    if (response.data.isEmpty) {
      throw const FormatException('KWP DTC response is missing its count');
    }
    final count = response.data.first;
    final requiredLength = 1 + count * 3;
    if (response.data.length < requiredLength) {
      throw const FormatException('KWP DTC response rows are truncated');
    }

    final dtcs = <KwpDtc>[];
    for (var offset = 1; offset < requiredLength; offset += 3) {
      dtcs.add(
        KwpDtc(
          code: (response.data[offset] << 8) | response.data[offset + 1],
          opaqueRecordByte: response.data[offset + 2],
        ),
      );
    }
    return KwpDtcReport(dtcs: List.unmodifiable(dtcs));
  }

  /// Clears diagnostic trouble codes using standard KWP Service 0x14 with [0xFF, 0xFF].
  Future<void> clearDtc() async {
    await _startCommunication();
    await _positive(0x14, const [
      0xff,
      0xff,
    ], timeout: const Duration(seconds: 5));
  }

  /// Requests a live parameter by identifier via KWP Service 0x17.
  Future<List<int>> readParameter(int parameterId) async {
    _checkU16(parameterId, 'parameterId');
    await _startCommunication();
    final response = await _positive(0x17, [
      parameterId >> 8,
      parameterId & 0xff,
    ]);
    return List.unmodifiable(response.data);
  }

  Future<KwpPositiveResponse> _positive(
    int service,
    List<int> parameters, {
    Duration? timeout,
  }) async {
    final payload = await link.request([
      service,
      ...parameters,
    ], timeout: timeout);
    final response = KwpResponse.decode(payload, requestService: service);
    if (response is KwpNegativeResponse) {
      throw KwpNegativeResponseException(response);
    }
    return response as KwpPositiveResponse;
  }

  Future<void> _startCommunication() async {
    if (!await link.startCommunication()) {
      throw StateError('BMW motorcycle KWP communication was not accepted');
    }
  }

  static void _checkU16(int value, String name) {
    if (value < 0 || value > 0xffff) {
      throw RangeError.range(value, 0, 0xffff, name);
    }
  }
}
