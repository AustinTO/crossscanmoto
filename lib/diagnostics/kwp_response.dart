/// A positive KWP response after ELM framing has been removed.
sealed class KwpResponse {
  const KwpResponse();

  factory KwpResponse.decode(
    List<int> payload, {
    required int requestService,
  }) {
    _checkService(requestService);
    if (payload.isEmpty || payload.any((byte) => byte < 0 || byte > 0xff)) {
      throw const FormatException('Invalid KWP payload or service');
    }

    if (payload.first == 0x7f) {
      if (payload.length != 3) {
        throw const FormatException('Malformed KWP negative response');
      }
      return KwpNegativeResponse(payload[1], payload[2]);
    }

    if (payload.first != requestService + 0x40) {
      throw const FormatException(
          'KWP response does not match request service');
    }
    return KwpPositiveResponse(
      payload.first,
      List.unmodifiable(payload.skip(1)),
    );
  }

  static void _checkService(int service) {
    if (service < 0 || service > 0xbf) {
      throw RangeError.range(service, 0, 0xbf, 'requestService');
    }
  }
}

final class KwpPositiveResponse extends KwpResponse {
  const KwpPositiveResponse(this.service, this.data);

  final int service;
  final List<int> data;
}

/// KWP's 0x7F response. `echoedService` is retained as sent by the ECU;
/// the 1.83 application checked the NRC in byte 2 but did not validate byte 1.
final class KwpNegativeResponse extends KwpResponse {
  const KwpNegativeResponse(this.echoedService, this.code);

  final int echoedService;
  final int code;
}

class KwpNegativeResponseException implements Exception {
  const KwpNegativeResponseException(this.response);

  final KwpNegativeResponse response;
  int get service => response.echoedService;
  int get code => response.code;

  @override
  String toString() =>
      'KWP service 0x${service.toRadixString(16).padLeft(2, '0')} rejected '
      '(NRC 0x${code.toRadixString(16).padLeft(2, '0')})';
}

/// A 1.83 TROUBLECODES response record. The third row byte is preserved as
/// opaque data; the source parser read only the two-byte code from each row.
class KwpDtc {
  const KwpDtc({required this.code, required this.opaqueRecordByte});

  final int code;
  final int opaqueRecordByte;
}

class KwpDtcReport {
  const KwpDtcReport({required this.dtcs});

  final List<KwpDtc> dtcs;
}
