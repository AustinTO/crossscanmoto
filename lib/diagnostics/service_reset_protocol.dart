import 'uds_client.dart';
import 'uds_response.dart';

/// Maintenance protocol families for BMW Motorrad UDS service operations.
///
/// `udsServiceData` handles WriteDataByIdentifier (0x2E) and ReadDataByIdentifier (0x22)
/// service reset, date/time synchronization, and service mileage calibration.
enum BmwServiceResetProfile {
  udsServiceData,
  @Deprecated('Use udsServiceData')
  sl0UdsServiceData,
}

/// Supported BMW Motorrad engine and vehicle controller definitions that support
/// standard UDS service reset and interval calibration.
abstract final class BmwServiceResetCatalog {
  static const supportedUdsEcuKeys = <String>{
    'cuX_BMSX',
    'cuX_BMSE2B',
    'cuX_BMSE2',
    'cuX_BMSMP1',
    'cuX_BMSO1',
  };

  @Deprecated('Use supportedUdsEcuKeys')
  static const sl0UdsEcuKeys = supportedUdsEcuKeys;

  /// Returns true if the specified control unit supports UDS service resets.
  static bool supportsEcuKey(String ecuKey) =>
      supportedUdsEcuKeys.contains(ecuKey);
}

/// Service reset action types for BMW Motorrad maintenance operations.
enum BmwServiceResetAction {
  /// All service parameters: vehicle clock/date, next-service date, then mileage.
  all,

  /// Set the motorcycle's displayed vehicle clock/date.
  vehicleDateTime,

  /// Set the next service date.
  nextServiceDate,

  /// Set the next service mileage value.
  nextServiceMileage,
}

class BmwServiceResetWrite {
  const BmwServiceResetWrite({required this.did, required this.data});

  final int did;
  final List<int> data;

  List<int> get request => [0x2e, (did >> 8) & 0xff, did & 0xff, ...data];
}

class BmwServiceResetResult {
  const BmwServiceResetResult({
    required this.profile,
    required this.action,
    required this.writtenDids,
    required this.readback,
  });

  final BmwServiceResetProfile profile;
  final BmwServiceResetAction action;
  final List<int> writtenDids;

  /// Raw UDS DID values read after the writes, in MotoScan's order: E119
  /// odometer, E12B vehicle clock/date, E12D next mileage, E12C next date.
  final Map<int, List<int>> readback;

  int? get odometerKilometers {
    final bytes = readback[0xe119];
    if (bytes == null || bytes.length != 4) return null;
    return (bytes[0] << 24) | (bytes[1] << 16) | (bytes[2] << 8) | bytes[3];
  }
}

/// Executes the recovered UDS service-data handler over an already configured
/// ECU-specific request link. The request payloads contain no ECU address; the
/// caller must select the correct ECU before invoking this class.
class BmwServiceResetProtocol {
  BmwServiceResetProtocol({
    required this.link,
    required this.profile,
    required this.ecuKey,
    this.writeTimeout = const Duration(seconds: 2),
    this.readbackTimeout = const Duration(seconds: 1),
    Future<void> Function(Duration)? delay,
  }) : _delay = delay ?? _defaultDelay;

  final UdsRequestLink link;
  final BmwServiceResetProfile profile;
  final String ecuKey;
  final Duration writeTimeout;
  final Duration readbackTimeout;
  final Future<void> Function(Duration) _delay;

  static const int vehicleDateTimeDid = 0xe12b;
  static const int nextServiceDateDid = 0xe12c;
  static const int nextServiceMileageDid = 0xe12d;
  static const int odometerDid = 0xe119;

  /// Encodes standard UDS WriteDataByIdentifier (0x2E) payloads for the specified maintenance action.
  static List<BmwServiceResetWrite> encodeWrites({
    required BmwServiceResetAction action,
    required DateTime vehicleDateTime,
    required DateTime nextServiceDate,
    required int nextServiceMileage,
  }) {
    if (nextServiceMileage < 0 || nextServiceMileage > 0xffff) {
      throw RangeError.range(
        nextServiceMileage,
        0,
        0xffff,
        'nextServiceMileage',
      );
    }

    final writes = <BmwServiceResetWrite>[];
    if (action == BmwServiceResetAction.all ||
        action == BmwServiceResetAction.vehicleDateTime) {
      writes.add(
        BmwServiceResetWrite(
          did: vehicleDateTimeDid,
          data: List.unmodifiable(_encodeVehicleClock(vehicleDateTime)),
        ),
      );
    }
    if (action == BmwServiceResetAction.all ||
        action == BmwServiceResetAction.nextServiceDate) {
      writes.add(
        BmwServiceResetWrite(
          did: nextServiceDateDid,
          data: List.unmodifiable(_encodeDate(nextServiceDate)),
        ),
      );
    }
    if (action == BmwServiceResetAction.all ||
        action == BmwServiceResetAction.nextServiceMileage) {
      // 16-bit big-endian service interval distance.
      writes.add(
        BmwServiceResetWrite(
          did: nextServiceMileageDid,
          data: List.unmodifiable([
            (nextServiceMileage >> 8) & 0xff,
            nextServiceMileage & 0xff,
          ]),
        ),
      );
    }
    return List.unmodifiable(writes);
  }

  Future<BmwServiceResetResult> execute({
    required BmwServiceResetAction action,
    required DateTime vehicleDateTime,
    required DateTime nextServiceDate,
    required int nextServiceMileage,
  }) async {
    if ((profile != BmwServiceResetProfile.udsServiceData &&
            profile != BmwServiceResetProfile.sl0UdsServiceData) ||
        !BmwServiceResetCatalog.supportsEcuKey(ecuKey)) {
      throw UnsupportedError('Unsupported BMW service-reset profile: $profile');
    }

    final writes = encodeWrites(
      action: action,
      vehicleDateTime: vehicleDateTime,
      nextServiceDate: nextServiceDate,
      nextServiceMileage: nextServiceMileage,
    );

    for (final write in writes) {
      final responseBytes = await _write(write.request);
      final response = UdsResponse.decode(responseBytes, requestService: 0x2e);
      if (response is UdsNegativeResponse) {
        throw UdsNegativeResponseException(response);
      }
      final positive = response as UdsPositiveResponse;
      if (positive.data.length != 2 ||
          positive.data[0] != 0xe1 ||
          positive.data[1] != (write.did & 0xff)) {
        throw FormatException(
          'WriteDataByIdentifier did not echo DID 0x${write.did.toRadixString(16)}',
        );
      }
    }

    final client = UdsClient(link, timeout: readbackTimeout);
    final readback = <int, List<int>>{};
    for (final did in const [
      odometerDid,
      vehicleDateTimeDid,
      nextServiceMileageDid,
      nextServiceDateDid,
    ]) {
      readback[did] = await client.readDataByIdentifier(did);
    }

    for (final write in writes) {
      final actual = readback[write.did]!;
      // The bike clock's seconds can advance between write and readback. The
      // DEX displays/validates its calendar date, so compare day/month/year;
      // compare all bytes for the next-service date and mileage DIDs.
      final expectedComparable = write.did == vehicleDateTimeDid
          ? write.data.skip(3).toList(growable: false)
          : write.data;
      final actualComparable =
          write.did == vehicleDateTimeDid && actual.length >= 7
          ? actual.skip(3).toList(growable: false)
          : actual;
      if (!_sameBytes(actualComparable, expectedComparable)) {
        throw FormatException(
          'Service reset readback did not match DID 0x${write.did.toRadixString(16)}',
        );
      }
    }

    final immutableReadback = <int, List<int>>{
      for (final entry in readback.entries)
        entry.key: List<int>.unmodifiable(entry.value),
    };

    return BmwServiceResetResult(
      profile: profile,
      action: action,
      writtenDids: List.unmodifiable(writes.map((write) => write.did)),
      readback: Map<int, List<int>>.unmodifiable(immutableReadback),
    );
  }

  Future<List<int>> _write(List<int> payload) async {
    try {
      return await link.request(payload, timeout: writeTimeout);
    } finally {
      // Settle delay of 1.5 s after each write transaction for non-volatile memory write cycle.
      await _delay(const Duration(milliseconds: 1500));
    }
  }

  static List<int> _encodeVehicleClock(DateTime value) {
    final local = value.toLocal();
    return [
      local.hour,
      local.minute,
      local.second,
      local.day,
      local.month,
      (local.year >> 8) & 0xff,
      local.year & 0xff,
    ];
  }

  static List<int> _encodeDate(DateTime value) {
    final local = value.toLocal();
    return [
      local.day,
      local.month,
      (local.year >> 8) & 0xff,
      local.year & 0xff,
    ];
  }

  static bool _sameBytes(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  static Future<void> _defaultDelay(Duration duration) =>
      Future<void>.delayed(duration);
}
