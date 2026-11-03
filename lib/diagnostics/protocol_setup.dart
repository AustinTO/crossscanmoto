import 'elm_session.dart';
import 'uds_client.dart';

/// Adapter profiles with verified BMW UDS STN/OBDLink hardware extension support.
enum BmwUdsAdapterType {
  obdLinkLx,
  obdLinkMx,
  obdLinkMxPlus,
  obdLinkMxWifi,
  viaKenStn1170,
  vLinkerFs,
  vLinkerMc,
  vLinkerMs,
  vLinkerFd,
  caristaEvo,
  unknown,
}

/// BMW motorcycle UDS setup and ELM request link.
///
/// `id` is passed through Java's `%02x` formatting semantics: two digits is a
/// minimum width, and the DEX contains no 8-bit range check. Callers retain
/// responsibility for supplying an ECU identifier appropriate to their bike.
class BmwBikeUdsLink implements UdsRequestLink {
  BmwBikeUdsLink(this.session, {this.adapterType});

  final ElmSession session;
  final BmwUdsAdapterType? adapterType;
  int? _configuredId;

  bool get isConfigured => _configuredId != null;

  /// Runs the observed enum-18 setup sequence. The same successful `(BMW UDS,
  /// id)` selection is cached, matching VciELM327's current protocol/id cache.
  Future<bool> configure({required int id}) async {
    if (_configuredId == id) return true;

    final idHex = _javaHex(id);
    // Once a new target's setup begins, the previous ECU selection is no
    // longer safe to use if any adapter command fails or times out.
    _configuredId = null;
    final requiredCommands = <String>[
      'ATSPB',
      'ATPBC101',
      'ATSH6F1',
      'ATFCSH6F1',
      'ATFCSD${idHex}300008',
      'ATFCSM1',
      'ATCEA$idHex',
      'ATCM7FF',
      'ATCF6$idHex',
      'ATST90',
      'ATBI',
    ];

    for (final command in requiredCommands) {
      final response = await session.command(command);
      if (!_hasOk(response)) return false;
    }

    if (_usesStnUdsExtensions(adapterType)) {
      // Configure STN CAN segment filters and flow control addressing.
      await session.command('STCSEGT1');
      await session.command('STCFCPC');
      final response = await session.command('STCFCPA 6F1$idHex,6${idHex}F3');
      if (!_hasOk(response)) return false;
    }

    _configuredId = id;
    return true;
  }

  /// Sends an application payload as uppercase hexadecimal ASCII.
  Future<List<int>> request(List<int> payload, {Duration? timeout}) async {
    if (!isConfigured) {
      return Future.error(
        StateError('Configure BMW UDS before sending a request'),
      );
    }
    if (payload.isEmpty || payload.any((byte) => byte < 0 || byte > 255)) {
      return Future.error(
        ArgumentError('Expected nonempty bytes in range 0..255'),
      );
    }
    final command = payload
        .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
        .join()
        .toUpperCase();
    final response = timeout == null
        ? await session.command(command)
        : await session.command(command, timeout: timeout);
    final applicationPayload = decodeSingleTokenResponse(response.lines);
    if (applicationPayload.length == 3 &&
        applicationPayload[0] == 0x7f &&
        applicationPayload[2] == 0x78) {
      throw const FormatException(
        'UDS response pending is unsupported: ELM prompt ended before a final response',
      );
    }
    return applicationPayload;
  }

  /// Decodes single-token or multi-frame BMW Motorrad UDS framing.
  ///
  /// Discards the first character, bytes 0..1 are adapter framing.
  /// Supports:
  /// - Standard single-token UDS framing (byte 2 is length, byte 3+ is payload).
  /// - Extended NRC 0x78 (response pending) sequences drained before the final response.
  /// - ISO-TP multi-frame reassembly (First Frame PCI 0x10, Consecutive Frames PCI 0x20).
  /// - ELM indexed multi-line sequences ('0:', '1:', etc.).
  static List<int> decodeSingleTokenResponse(List<String> lines) {
    final tokens = lines
        .map((l) => l.replaceAll('>', '').trim())
        .where((l) =>
            l.isNotEmpty &&
            !l.toUpperCase().startsWith('SEARCHING') &&
            !l.toUpperCase().startsWith('BUS INIT') &&
            !l.toUpperCase().startsWith('STOPPED') &&
            !l.toUpperCase().startsWith('NO DATA') &&
            !l.toUpperCase().startsWith('?'))
        .toList();

    if (tokens.isEmpty || tokens.first.length < 2) {
      throw const FormatException(
        'BMW UDS decoder supports exactly one nonempty response token',
      );
    }

    // ELM auto-indexed multi-line response (e.g. "0: 62 F1 90 ...")
    if (tokens.every((t) => RegExp(r'^\d+:').hasMatch(t))) {
      return _decodeElmIndexedResponse(tokens);
    }

    // Drain all NRC 0x78 response pending tokens
    final nonPendingTokens = <String>[];
    List<int>? lastPendingPayload;

    for (final token in tokens) {
      try {
        final decoded = _decodeSingleTokenHex(token);
        if (decoded.length == 3 && decoded[0] == 0x7f && decoded[2] == 0x78) {
          lastPendingPayload = decoded;
          continue;
        }
      } catch (_) {
        // Not a single-frame pending token; could be multi-frame
      }
      nonPendingTokens.add(token);
    }

    if (nonPendingTokens.isEmpty) {
      if (lastPendingPayload != null) {
        return lastPendingPayload;
      }
      throw const FormatException(
        'BMW UDS decoder supports exactly one nonempty response token',
      );
    }

    if (nonPendingTokens.length == 1) {
      return _decodeSingleTokenHex(nonPendingTokens.first);
    }

    // Attempt ISO-TP multi-frame reassembly
    try {
      return _decodeIsoTpMultiFrame(nonPendingTokens);
    } catch (_) {
      throw const FormatException(
        'BMW UDS decoder supports exactly one nonempty response token',
      );
    }
  }

  static List<int> _decodeIsoTpMultiFrame(List<String> tokens) {
    final firstRaw = _parseHexBytes(tokens.first);
    if (firstRaw.length < 4) {
      throw const FormatException('ISO-TP first frame is truncated');
    }
    final pci = firstRaw[2];
    if ((pci & 0xf0) != 0x10) {
      throw const FormatException('Expected ISO-TP First Frame (PCI 0x10)');
    }
    final totalLength = ((pci & 0x0f) << 8) | firstRaw[3];
    if (totalLength <= 0) {
      throw const FormatException('Invalid ISO-TP total length');
    }

    final payload = <int>[...firstRaw.skip(4)];
    var expectedSequence = 1;

    for (var i = 1; i < tokens.length && payload.length < totalLength; i++) {
      final cfRaw = _parseHexBytes(tokens[i]);
      if (cfRaw.length < 3) {
        throw const FormatException('ISO-TP consecutive frame is truncated');
      }
      final cfPci = cfRaw[2];
      if ((cfPci & 0xf0) != 0x20) {
        throw const FormatException('Expected ISO-TP Consecutive Frame (PCI 0x20)');
      }
      final seq = cfPci & 0x0f;
      if (seq != (expectedSequence & 0x0f)) {
        throw FormatException('ISO-TP sequence error: expected $expectedSequence, got $seq');
      }
      expectedSequence++;
      payload.addAll(cfRaw.skip(3));
    }

    if (payload.length < totalLength) {
      throw const FormatException('ISO-TP payload incomplete');
    }
    return List.unmodifiable(payload.take(totalLength));
  }

  static List<int> _decodeElmIndexedResponse(List<String> tokens) {
    final payload = <int>[];
    var expectedIndex = 0;
    for (final token in tokens) {
      final colonIdx = token.indexOf(':');
      if (colonIdx < 0) {
        throw const FormatException('Malformed ELM indexed line missing colon');
      }
      final indexStr = token.substring(0, colonIdx).trim();
      final index = int.tryParse(indexStr);
      if (index == null || index != expectedIndex) {
        throw FormatException(
            'ELM indexed sequence non-contiguous: expected index $expectedIndex, got $indexStr');
      }
      expectedIndex++;
      final hexPart = token.substring(colonIdx + 1).replaceAll(' ', '');
      if (hexPart.length.isOdd || !RegExp(r'^[0-9a-fA-F]+$').hasMatch(hexPart)) {
        throw const FormatException('Malformed ELM indexed hex token');
      }
      for (var i = 0; i < hexPart.length; i += 2) {
        payload.add(int.parse(hexPart.substring(i, i + 2), radix: 16));
      }
    }
    return List.unmodifiable(payload);
  }

  static List<int> _parseHexBytes(String rawToken) {
    final trimmed = rawToken.trim();
    if (trimmed.length < 2) {
      throw const FormatException('Malformed BMW UDS response token');
    }
    final hex = trimmed.substring(1);
    if (hex.length.isOdd || !RegExp(r'^[0-9a-fA-F]+$').hasMatch(hex)) {
      throw const FormatException('Malformed BMW UDS response token');
    }
    final frame = <int>[];
    for (var offset = 0; offset < hex.length; offset += 2) {
      frame.add(int.parse(hex.substring(offset, offset + 2), radix: 16));
    }
    return frame;
  }

  static List<int> _decodeSingleTokenHex(String rawToken) {
    final frame = _parseHexBytes(rawToken);
    if (frame.length < 3) {
      throw const FormatException('BMW UDS response header is truncated');
    }
    final payloadLength = frame[2];
    if (frame.length < payloadLength + 3) {
      throw const FormatException('BMW UDS response payload is truncated');
    }
    return List.unmodifiable(frame.skip(3).take(payloadLength));
  }

  static bool _usesStnUdsExtensions(BmwUdsAdapterType? adapter) => const {
    BmwUdsAdapterType.obdLinkLx,
    BmwUdsAdapterType.obdLinkMx,
    BmwUdsAdapterType.obdLinkMxPlus,
    BmwUdsAdapterType.vLinkerFs,
    BmwUdsAdapterType.vLinkerMc,
    BmwUdsAdapterType.vLinkerMs,
    BmwUdsAdapterType.vLinkerFd,
    BmwUdsAdapterType.caristaEvo,
  }.contains(adapter);

  static String _javaHex(int value) {
    if (value < -0x80000000 || value > 0x7fffffff) {
      throw RangeError.range(value, -0x80000000, 0x7fffffff, 'id');
    }
    final unsigned = value < 0 ? value.toUnsigned(32) : value;
    return unsigned.toRadixString(16).padLeft(2, '0');
  }

  static bool _hasOk(AdapterResponse response) =>
      response.lines.any((line) => line.trim().toUpperCase() == 'OK');
}
