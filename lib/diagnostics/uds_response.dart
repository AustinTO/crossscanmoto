/// A decoded UDS application payload, after transport framing is removed.
sealed class UdsResponse {
  const UdsResponse();
  factory UdsResponse.decode(List<int> payload, {required int requestService}) {
    if (requestService < 0 || requestService > 0xBF || payload.isEmpty ||
        payload.any((byte) => byte < 0 || byte > 255)) {
      throw const FormatException('Invalid UDS payload or service');
    }
    if (payload.first == 0x7F) {
      if (payload.length != 3 || payload[1] != requestService) {
        throw const FormatException('Malformed or mismatched negative response');
      }
      return UdsNegativeResponse(payload[1], payload[2]);
    }
    if (payload.first != requestService + 0x40) {
      throw const FormatException('Response does not match request service');
    }
    return UdsPositiveResponse(payload.first, List.unmodifiable(payload.skip(1)));
  }
}
final class UdsPositiveResponse extends UdsResponse {
  const UdsPositiveResponse(this.service, this.data);
  final int service;
  final List<int> data;
}
final class UdsNegativeResponse extends UdsResponse {
  const UdsNegativeResponse(this.service, this.code);
  final int service;
  final int code;
  bool get isPending => code == 0x78;
  String get description => switch (code) {
    0x10 => 'General reject',
    0x11 => 'Service not supported',
    0x12 => 'Subfunction not supported',
    0x13 => 'Incorrect message length or format',
    0x21 => 'Busy; repeat request',
    0x22 => 'Conditions not correct',
    0x24 => 'Request sequence error',
    0x31 => 'Request out of range',
    0x33 => 'Security access denied',
    0x35 => 'Invalid key',
    0x36 => 'Exceeded number of attempts',
    0x37 => 'Required delay not expired',
    0x78 => 'Response pending',
    0x7E => 'Subfunction not supported in active session',
    0x7F => 'Service not supported in active session',
    _ => 'Negative response 0x${code.toRadixString(16).padLeft(2, '0')}',
  };
}
