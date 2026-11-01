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
      final response = await session.command(
        'STCFCPA 6F1$idHex,6${idHex}F3',
      );
      if (!_hasOk(response)) return false;
    }

    _configuredId = id;
    return true;
  }

  /// Sends an application payload as uppercase hexadecimal ASCII.
  Future<List<int>> request(
    List<int> payload, {
    Duration? timeout,
  }) async {
    if (!isConfigured) {
      return Future.error(
          StateError('Configure BMW UDS before sending a request'));
    }
    if (payload.isEmpty || payload.any((byte) => byte < 0 || byte > 255)) {
      return Future.error(
          ArgumentError('Expected nonempty bytes in range 0..255'));
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

  /// Decodes single-token BMW Motorrad UDS framing.
  ///
  /// The first character is discarded, bytes 0..1 are adapter framing, byte 2 is
  /// application payload length, and the application payload starts at byte 3.
  static List<int> decodeSingleTokenResponse(List<String> lines) {
    if (lines.length != 1 || lines.single.length < 2) {
      throw const FormatException(
        'BMW UDS decoder supports exactly one nonempty response token',
      );
    }
    final hex = lines.single.substring(1);
    if (hex.length.isOdd || !RegExp(r'^[0-9a-fA-F]+$').hasMatch(hex)) {
      throw const FormatException('Malformed BMW UDS response token');
    }
    final frame = <int>[];
    for (var offset = 0; offset < hex.length; offset += 2) {
      frame.add(int.parse(hex.substring(offset, offset + 2), radix: 16));
    }
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
      response.lines.any((line) => line.contains('OK'));
}
