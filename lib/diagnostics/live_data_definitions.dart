/// Result decoding recovered from MotoScan's PARAMS_RES parser.
/// Raw bytes accompany source-derived values and original placeholder outputs.
abstract final class BmwLiveDataDecoder {
  static const _resultNames = <int, BmwResultFormat>{
    1: BmwResultFormat.number,
    2: BmwResultFormat.list,
    3: BmwResultFormat.digital,
    4: BmwResultFormat.ascii,
    5: BmwResultFormat.hex,
    6: BmwResultFormat.bitfield,
    7: BmwResultFormat.dateTime,
    8: BmwResultFormat.bmwUdSecUsn,
    9: BmwResultFormat.tabGlobal,
  };
  static const _cTypes = <String, ({int width, bool signed, bool castInt})>{
    'unsigned char': (width: 1, signed: false, castInt: false),
    // Recovered branch target treats `signed char` as unsigned char.
    'signed char': (width: 1, signed: false, castInt: false),
    'char': (width: 1, signed: true, castInt: false),
    'unsigned int': (width: 2, signed: false, castInt: false),
    'int': (width: 2, signed: true, castInt: false),
    'signed int': (width: 2, signed: true, castInt: false),
    'unsigned long': (width: 4, signed: false, castInt: true),
  };

  static bool ecuMatches(String? selectedEcu, String? connectedEcu) =>
      selectedEcu != null &&
      connectedEcu != null &&
      selectedEcu == connectedEcu;

  /// [udsData] is the application data after UDS SID and DID were removed.
  /// The original parser's byte offsets include those three response bytes,
  /// so they are accounted for when translating to this app's response shape.
  static BmwNumericResult decodeNumber({
    required String parameterRaw,
    required String resultRaw,
    required List<int> udsData,
  }) {
    final parameter = parameterRaw.split(';');
    final result = resultRaw.split(';');
    if (parameter.length <= 3 || result.length <= 13) {
      return const BmwNumericResult.raw('Incomplete source row');
    }
    final resultType = _integer(result[3]);
    if (resultType != 1) {
      return const BmwNumericResult.raw('Non-NUMBER result type');
    }
    final baseOffset = _integer(parameter[3]);
    final resultOffset = _integer(result[7]);
    final length = _integer(result[8]);
    final parameterId = _integer(parameter[0]);
    final resultParentId = _integer(result[1]);
    final cType = _cTypes[result[6]];
    final multiplier = _number(result[11], blankFallback: 1);
    final divisor = _number(result[12], blankFallback: 1);
    final additiveOffset = _number(result[13], blankFallback: 0);
    if (baseOffset == null ||
        resultOffset == null ||
        length == null ||
        parameterId == null ||
        resultParentId != parameterId ||
        cType == null ||
        length != cType.width ||
        multiplier == null ||
        divisor == null ||
        additiveOffset == null ||
        divisor == 0 ||
        !multiplier.isFinite ||
        !divisor.isFinite ||
        !additiveOffset.isFinite) {
      return const BmwNumericResult.raw(
        'Unsupported or incomplete numeric definition',
      );
    }

    final start = baseOffset + resultOffset - 3;
    final end = start + length;
    if (start < 0 ||
        end > udsData.length ||
        udsData.any((byte) => byte < 0 || byte > 255)) {
      return const BmwNumericResult.raw(
        'Response is too short for numeric definition',
      );
    }
    final unsigned = udsData
        .sublist(start, end)
        .fold<int>(0, (value, byte) => (value << 8) | byte);
    final bits = cType.width * 8;
    var raw = unsigned;
    if (cType.signed && (unsigned & (1 << (bits - 1))) != 0) {
      raw = unsigned - (1 << bits);
    } else if (cType.castInt && (unsigned & (1 << 31)) != 0) {
      // ob2.D casts the unsigned 32-bit Java long to int, preserving low bits.
      raw = unsigned - (1 << 32);
    }
    final value = raw * multiplier / divisor + additiveOffset;
    if (!value.isFinite) {
      return const BmwNumericResult.raw(
        'Numeric result is outside the supported range',
      );
    }
    return BmwNumericResult.decoded(raw: raw, value: value);
  }

  /// Decodes one PARAMS_RES row while retaining the exact extracted bytes.
  /// OEM/global display branches retain source fallbacks when lookup data is
  /// unavailable, alongside the exact extracted response slice.
  static BmwLiveResult decodeResult({
    required String parameterRaw,
    required String resultRaw,
    required List<int> udsData,
    List<String> tabsRaw = const [],
    Map<String, String> tabTexts = const {},
    List<String> tabGlobalRaw = const [],
    String? tabGlobalKeyHeader,
    String? tabGlobalValueHeader,
    String unit = '',
    String decimalSeparator = '.',
    String zeroDigit = '0',
  }) {
    final fields = resultRaw.split(';');
    final displayUnit = tabsRaw.isEmpty && unit != '-' ? unit : '';
    BmwLiveResult decodedResult({
      required BmwResultFormat format,
      required List<int> rawBytes,
      int? rawValue,
      required String displayValue,
      bool isPlaceholder = false,
    }) => BmwLiveResult.decoded(
      format: format,
      rawBytes: rawBytes,
      rawValue: rawValue,
      displayValue: displayValue,
      displayUnit: displayUnit,
      isPlaceholder: isPlaceholder,
    );
    BmwLiveResult unresolvedResult({
      BmwResultFormat? format,
      List<int> rawBytes = const [],
      int? rawValue,
      required String reason,
    }) => BmwLiveResult.unresolved(
      format: format,
      rawBytes: rawBytes,
      rawValue: rawValue,
      reason: reason,
      displayUnit: displayUnit,
    );
    if (fields.length <= 13) {
      final typeId = fields.length > 3 ? _integer(fields[3]) : null;
      return unresolvedResult(
        format: typeId == null ? null : _resultNames[typeId],
        rawBytes: fields.length > 8
            ? _resultBytes(parameterRaw, fields, udsData) ?? const []
            : const [],
        reason: 'Incomplete source row',
      );
    }
    final resultId = _integer(fields[0]);
    final parentId = _integer(fields[1]);
    final parameterFields = parameterRaw.split(';');
    final parameterId = parameterFields.isEmpty
        ? null
        : _integer(parameterFields[0]);
    final typeId = _integer(fields[3]);
    final format = typeId == null ? null : _resultNames[typeId];
    final extractedBytes = _resultBytes(parameterRaw, fields, udsData);
    final bytes = extractedBytes ?? const <int>[];
    if (resultId == null || parameterId == null || parentId != parameterId) {
      return unresolvedResult(
        format: format,
        rawBytes: bytes,
        reason: 'Result does not match its parent parameter',
      );
    }
    if (format == null) {
      return unresolvedResult(rawBytes: bytes, reason: 'Unknown result type');
    }

    if (format == BmwResultFormat.number) {
      final numeric = decodeNumber(
        parameterRaw: parameterRaw,
        resultRaw: resultRaw,
        udsData: udsData,
      );
      if (!numeric.isDecoded) {
        return unresolvedResult(
          format: format,
          rawBytes: bytes,
          reason: numeric.reason ?? 'Numeric result unresolved',
        );
      }
      final scale = _number(fields[11], blankFallback: 1);
      final divisor = _number(fields[12], blankFallback: 1);
      final value = numeric.value!;
      final text = _formatFixed(
        value,
        scale == 1 && divisor == 1 ? 0 : 2,
        decimalSeparator: decimalSeparator,
        zeroDigit: zeroDigit,
      );
      return decodedResult(
        format: format,
        rawBytes: bytes,
        rawValue: numeric.raw,
        displayValue: text,
      );
    }

    if (extractedBytes == null) {
      return unresolvedResult(
        format: format,
        reason: 'Response is too short for result definition',
      );
    }
    switch (format) {
      case BmwResultFormat.list:
      case BmwResultFormat.digital:
        final rawValue = _decodeCValue(bytes, fields[6]);
        if (rawValue == null) {
          return unresolvedResult(
            format: format,
            rawBytes: bytes,
            reason: 'Unsupported C type for table result',
          );
        }
        var lookupValue = rawValue;
        if (format == BmwResultFormat.digital && fields[9].trim().isNotEmpty) {
          final mask = _integer(fields[9]);
          if (mask == null) {
            return unresolvedResult(
              format: format,
              rawBytes: bytes,
              rawValue: rawValue,
              reason: 'Malformed DIGITAL mask',
            );
          }
          lookupValue = (rawValue & mask) > 0 ? 1 : 0;
        }
        for (final tab in tabsRaw) {
          final tabFields = tab.split(';');
          if (tabFields.length >= 4 &&
              _integer(tabFields[1]) == resultId &&
              _integer(tabFields[2]) == lookupValue) {
            final label = tabTexts[tabFields[3]];
            if (label == null) {
              return unresolvedResult(
                format: format,
                rawBytes: bytes,
                rawValue: rawValue,
                reason: 'Localized TAB value text is unavailable',
              );
            }
            return decodedResult(
              format: format,
              rawBytes: bytes,
              rawValue: rawValue,
              displayValue: label,
            );
          }
        }
        return decodedResult(
          format: format,
          rawBytes: bytes,
          rawValue: rawValue,
          displayValue: '-',
        );
      case BmwResultFormat.ascii:
        return decodedResult(
          format: format,
          rawBytes: bytes,
          displayValue: 'ASCII-VALUE',
          isPlaceholder: true,
        );
      case BmwResultFormat.hex:
        return decodedResult(
          format: format,
          rawBytes: bytes,
          displayValue: bytes
              .map(
                (byte) => byte.toRadixString(16).padLeft(2, '0').toUpperCase(),
              )
              .join(),
        );
      case BmwResultFormat.bitfield:
        return decodedResult(
          format: format,
          rawBytes: bytes,
          displayValue: 'BITFIELD-VALUE',
          isPlaceholder: true,
        );
      case BmwResultFormat.dateTime:
        if (_integer(fields[10]) == 1) {
          if (bytes.length < 3) {
            return unresolvedResult(
              format: format,
              rawBytes: bytes,
              reason: 'DATETIME value requires three bytes',
            );
          }
          final date = [
            bytes[2],
            bytes[1],
            bytes[0],
          ].map((byte) => byte.toRadixString(16).padLeft(2, '0')).join('.');
          return decodedResult(
            format: format,
            rawBytes: bytes,
            displayValue: '${date.substring(0, 5)}.20${date.substring(6)}',
          );
        }
        return decodedResult(
          format: format,
          rawBytes: bytes,
          displayValue: bytes
              .map(
                (byte) => byte.toRadixString(16).padLeft(2, '0').toUpperCase(),
              )
              .join(),
        );
      case BmwResultFormat.bmwUdSecUsn:
        if (bytes.isEmpty) {
          return unresolvedResult(
            format: format,
            rawBytes: bytes,
            reason: 'BMWUDSECUSN requires at least one byte',
          );
        }
        final first = _signedByte(bytes.first);
        if (first < 48) {
          final value = StringBuffer();
          for (final byte in bytes) {
            final signed = _signedByte(byte);
            value.write(
              signed < 32 || signed >= 127
                  ? ' '
                  : String.fromCharCode(signed + 48),
            );
          }
          return decodedResult(
            format: format,
            rawBytes: bytes,
            displayValue: value.toString(),
          );
        }
        return decodedResult(
          format: format,
          rawBytes: bytes,
          displayValue: String.fromCharCodes(
            bytes.map((byte) {
              final signed = _signedByte(byte);
              return signed < 32 || signed >= 127 ? 32 : signed;
            }),
          ).trim(),
        );
      case BmwResultFormat.tabGlobal:
        final hex = bytes
            .map((byte) => byte.toRadixString(16).padLeft(2, '0').toUpperCase())
            .join();
        if (bytes.isEmpty ||
            tabGlobalRaw.isEmpty ||
            tabGlobalKeyHeader == null ||
            tabGlobalValueHeader == null) {
          return decodedResult(
            format: format,
            rawBytes: bytes,
            displayValue: hex,
          );
        }
        final headers = tabGlobalRaw.first.split(';');
        final keyColumn = headers.indexOf(tabGlobalKeyHeader);
        final valueColumn = headers.indexOf(tabGlobalValueHeader);
        if (keyColumn < 0 || valueColumn < 0) {
          return decodedResult(
            format: format,
            rawBytes: bytes,
            displayValue: hex,
          );
        }
        final unsigned = bytes.fold<int>(
          0,
          (value, byte) => (value << 8) | byte,
        );
        final signed = (bytes.first & 0x80) == 0
            ? unsigned
            : unsigned - (1 << (bytes.length * 8));
        final lowInt = signed & 0xffffffff;
        final lookup = lowInt >= 0x80000000 ? lowInt - 0x100000000 : lowInt;
        for (final row in tabGlobalRaw.skip(1)) {
          final fields = row.split(';');
          if (fields.length > keyColumn &&
              fields.length > valueColumn &&
              fields[keyColumn] == lookup.toString()) {
            return decodedResult(
              format: format,
              rawBytes: bytes,
              rawValue: lookup,
              displayValue: fields[valueColumn],
            );
          }
        }
        return decodedResult(
          format: format,
          rawBytes: bytes,
          displayValue: hex,
        );
      case BmwResultFormat.number:
        throw StateError('NUMBER branch handled above');
    }
  }

  static List<int>? _resultBytes(
    String parameterRaw,
    List<String> resultFields,
    List<int> udsData,
  ) {
    final parameterFields = parameterRaw.split(';');
    if (parameterFields.length <= 3 || resultFields.length <= 8) return null;
    final base = _integer(parameterFields[3]);
    final offset = _integer(resultFields[7]);
    final length = _integer(resultFields[8]);
    if (base == null || offset == null || length == null || length < 0)
      return null;
    final start = base + offset - 3;
    final end = start + length;
    if (start < 0 ||
        end > udsData.length ||
        udsData.any((byte) => byte < 0 || byte > 255))
      return null;
    return udsData.sublist(start, end);
  }

  static int? _decodeCValue(List<int> bytes, String type) {
    final info = _cTypes[type];
    if (info == null || info.width != bytes.length) return null;
    final unsigned = bytes.fold<int>(0, (value, byte) => (value << 8) | byte);
    final bits = info.width * 8;
    if (info.signed && (unsigned & (1 << (bits - 1))) != 0) {
      return unsigned - (1 << bits);
    }
    if (info.castInt && (unsigned & (1 << 31)) != 0) {
      return unsigned - (1 << 32);
    }
    return unsigned;
  }

  static int _signedByte(int byte) => byte >= 128 ? byte - 256 : byte;

  /// Mirrors Java Formatter's decimal HALF_UP behavior for `%f` output.
  /// Dart's toStringAsFixed rounds the exact binary value and differs at
  /// decimal ties such as 65.535, where Java formats the shortest decimal.
  static String _formatFixed(
    double value,
    int fractionDigits, {
    required String decimalSeparator,
    required String zeroDigit,
  }) {
    final negative = value.isNegative;
    final source = value.abs().toString().toLowerCase();
    final exponentAt = source.indexOf('e');
    final mantissa = exponentAt < 0 ? source : source.substring(0, exponentAt);
    final exponent = exponentAt < 0
        ? 0
        : int.parse(source.substring(exponentAt + 1));
    final pointAt = mantissa.indexOf('.');
    final decimalPlaces =
        (pointAt < 0 ? 0 : mantissa.length - pointAt - 1) - exponent;
    var digits = mantissa.replaceAll('.', '').replaceFirst(RegExp(r'^0+'), '');
    if (digits.isEmpty) digits = '0';
    var rounded = BigInt.parse(digits);
    final shift = fractionDigits - decimalPlaces;
    if (shift >= 0) {
      rounded *= BigInt.from(10).pow(shift);
    } else {
      final divisor = BigInt.from(10).pow(-shift);
      final remainder = rounded.remainder(divisor);
      rounded ~/= divisor;
      if (remainder * BigInt.two >= divisor) rounded += BigInt.one;
    }
    var text = rounded.toString();
    if (fractionDigits > 0) {
      text = text.padLeft(fractionDigits + 1, '0');
      final split = text.length - fractionDigits;
      text =
          '${text.substring(0, split)}$decimalSeparator${text.substring(split)}';
    }
    final zeroRunes = zeroDigit.runes;
    final zeroCodePoint = zeroRunes.isEmpty ? 48 : zeroRunes.first;
    final localizedDigits = String.fromCharCodes(
      text.runes.map(
        (rune) => rune >= 48 && rune <= 57 ? zeroCodePoint + rune - 48 : rune,
      ),
    );
    return negative ? '-$localizedDigits' : localizedDigits;
  }

  static int? _integer(String value) {
    var token = value.trim();
    if (token.isEmpty) return null;
    final sign = token.startsWith('-') ? -1 : 1;
    if (token.startsWith('+') || token.startsWith('-')) {
      token = token.substring(1);
    }
    var radix = 10;
    if (token.startsWith('0x') || token.startsWith('0X')) {
      radix = 16;
      token = token.substring(2);
    } else if (token.startsWith('#')) {
      radix = 16;
      token = token.substring(1);
    } else if (token.length > 1 && token.startsWith('0')) {
      radix = 8;
      token = token.substring(1);
    }
    final decoded = int.tryParse(token, radix: radix);
    return decoded == null ? null : sign * decoded;
  }

  static double? _number(String value, {required double blankFallback}) =>
      value.trim().isEmpty ? blankFallback : double.tryParse(value.trim());
}

enum BmwResultFormat {
  number,
  list,
  digital,
  ascii,
  hex,
  bitfield,
  dateTime,
  bmwUdSecUsn,
  tabGlobal,
}

final class BmwLiveResult {
  const BmwLiveResult._({
    this.format,
    this.rawBytes = const [],
    this.rawValue,
    this.displayValue,
    this.displayUnit = '',
    this.isPlaceholder = false,
    this.reason,
  });

  const BmwLiveResult.decoded({
    required BmwResultFormat format,
    required List<int> rawBytes,
    int? rawValue,
    required String displayValue,
    String displayUnit = '',
    bool isPlaceholder = false,
  }) : this._(
         format: format,
         rawBytes: rawBytes,
         rawValue: rawValue,
         displayValue: displayValue,
         displayUnit: displayUnit,
         isPlaceholder: isPlaceholder,
       );

  const BmwLiveResult.unresolved({
    BmwResultFormat? format,
    String displayUnit = '',
    List<int> rawBytes = const [],
    int? rawValue,
    required String reason,
  }) : this._(
         format: format,
         displayUnit: displayUnit,
         rawBytes: rawBytes,
         rawValue: rawValue,
         reason: reason,
       );

  final BmwResultFormat? format;
  final List<int> rawBytes;
  final int? rawValue;
  final String? displayValue;
  final String displayUnit;
  final bool isPlaceholder;
  final String? reason;
  bool get isDecoded => displayValue != null;
}

final class BmwNumericResult {
  const BmwNumericResult._({this.raw, this.value, this.reason});

  const BmwNumericResult.raw(String reason) : this._(reason: reason);

  const BmwNumericResult.decoded({required int raw, required double value})
    : this._(raw: raw, value: value);

  final int? raw;
  final double? value;
  final String? reason;

  bool get isDecoded => value != null;
}

/// Unit conversions for explicitly decoded, ECU-backed definitions.
/// No sensor readings, ranges, nominal values or DID assignments are guessed.
abstract final class BmwUnitConverter {
  static double toImperial(double metric, String unit) => switch (unit) {
    '°C' => metric * 9 / 5 + 32,
    'km/h' || 'km' => metric * 0.621371,
    'bar' => metric * 14.5038,
    _ => metric,
  };
}
