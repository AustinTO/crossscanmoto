import 'uds_response.dart';

/// Sends one complete UDS request payload and returns its final response.
///
/// Implementations must keep the request outstanding across NRC 0x78
/// (response pending) replies and resolve only when a final response arrives
/// or [timeout] expires. Payloads exclude ISO-TP framing.
abstract interface class UdsRequestLink {
  Future<List<int>> request(List<int> payload, {Duration? timeout});
}

class UdsNegativeResponseException implements Exception {
  const UdsNegativeResponseException(this.response);

  final UdsNegativeResponse response;
  int get service => response.service;
  int get code => response.code;
  String get description => response.description;

  @override
  String toString() =>
      'UDS service 0x${service.toRadixString(16).padLeft(2, '0')} rejected: '
      '$description (NRC 0x${code.toRadixString(16).padLeft(2, '0')})';
}

class UdsDtc {
  const UdsDtc({required this.code, required this.status});

  /// The three byte DTC value, preserving the ECU representation.
  final int code;
  final int status;
}

class UdsDtcReport {
  const UdsDtcReport({required this.statusAvailabilityMask, required this.dtcs});

  final int statusAvailabilityMask;
  final List<UdsDtc> dtcs;
}

/// Transport agnostic subset of UDS services used for diagnostics.
class UdsClient {
  UdsClient(this.link, {this.timeout});

  final UdsRequestLink link;
  final Duration? timeout;

  Future<List<int>> readDataByIdentifier(int did) async {
    _checkU16(did, 'DID');
    final response = await _positive(0x22, [did >> 8, did & 0xff]);
    if (response.data.length < 2) {
      throw const FormatException('ReadDataByIdentifier response is missing DID');
    }
    final returnedDid = (response.data[0] << 8) | response.data[1];
    if (returnedDid != did) {
      throw FormatException(
          'ReadDataByIdentifier returned DID 0x${returnedDid.toRadixString(16).padLeft(4, '0')} instead of 0x${did.toRadixString(16).padLeft(4, '0')}');
    }
    return List.unmodifiable(response.data.skip(2));
  }

  Future<UdsDtcReport> readDtcByStatusMask(int statusMask) async {
    _checkByte(statusMask, 'DTC status mask');
    final response = await _positive(0x19, [0x02, statusMask]);
    final data = response.data;
    if (data.length < 2 || data[0] != 0x02) {
      throw const FormatException('Invalid ReadDTCInformation subfunction response');
    }
    final records = data.skip(2).toList(growable: false);
    if (records.length % 4 != 0) {
      throw const FormatException('DTC records must contain three code bytes and one status byte');
    }
    final dtcs = <UdsDtc>[];
    for (var offset = 0; offset < records.length; offset += 4) {
      final code = (records[offset] << 16) |
          (records[offset + 1] << 8) |
          records[offset + 2];
      dtcs.add(UdsDtc(code: code, status: records[offset + 3]));
    }
    return UdsDtcReport(
      statusAvailabilityMask: data[1],
      dtcs: List.unmodifiable(dtcs),
    );
  }

  Future<void> clearDtc({int group = 0xffffff}) async {
    if (group < 0 || group > 0xffffff) {
      throw RangeError.range(group, 0, 0xffffff, 'group');
    }
    await _positive(
        0x14, [(group >> 16) & 0xff, (group >> 8) & 0xff, group & 0xff]);
  }

  /// Requests a diagnostic session; returns the ECU's session timing bytes.
  Future<List<int>> diagnosticSessionControl(int subfunction) async {
    _checkByte(subfunction, 'session subfunction');
    if ((subfunction & 0x80) != 0) {
      throw ArgumentError.value(subfunction, 'subfunction',
          'Suppress-positive-response bit is not supported');
    }
    final response = await _positive(0x10, [subfunction]);
    if (response.data.isEmpty || response.data.first != subfunction) {
      throw const FormatException('DiagnosticSessionControl response did not echo the session');
    }
    return List.unmodifiable(response.data.skip(1));
  }

  Future<UdsPositiveResponse> _positive(int service, List<int> parameters) async {
    final payload = await link.request([service, ...parameters], timeout: timeout);
    final response = UdsResponse.decode(payload, requestService: service);
    if (response is UdsNegativeResponse) {
      throw UdsNegativeResponseException(response);
    }
    return response as UdsPositiveResponse;
  }

  static void _checkByte(int value, String name) {
    if (value < 0 || value > 0xff) throw RangeError.range(value, 0, 0xff, name);
  }

  static void _checkU16(int value, String name) {
    if (value < 0 || value > 0xffff) throw RangeError.range(value, 0, 0xffff, name);
  }
}
