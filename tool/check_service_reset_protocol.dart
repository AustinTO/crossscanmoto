import '../lib/diagnostics/service_reset_protocol.dart';
import '../lib/diagnostics/uds_client.dart';

class FakeUdsLink implements UdsRequestLink {
  final requests = <List<int>>[];
  final values = <int, List<int>>{
    0xe119: [0, 0, 0x30, 0x39],
  };
  int? rejectWriteDid;
  int? mismatchReadbackDid;

  @override
  Future<List<int>> request(List<int> payload, {Duration? timeout}) async {
    requests.add(List.unmodifiable(payload));
    if (payload.first == 0x2e) {
      final did = (payload[1] << 8) | payload[2];
      if (rejectWriteDid == did) return [0x7f, 0x2e, 0x31];
      values[did] = List.unmodifiable(payload.skip(3));
      return [0x6e, payload[1], payload[2]];
    }
    if (payload.first == 0x22) {
      final did = (payload[1] << 8) | payload[2];
      final data = List<int>.of(values[did] ?? const <int>[]);
      if (mismatchReadbackDid == did && data.isNotEmpty) data[0] ^= 1;
      return [0x62, payload[1], payload[2], ...data];
    }
    throw StateError('Unexpected service 0x${payload.first.toRadixString(16)}');
  }
}

void check(bool value, String message) {
  if (!value) throw StateError(message);
}

Future<void> main() async {
  final link = FakeUdsLink();
  final delays = <Duration>[];
  final protocol = BmwServiceResetProtocol(
    link: link,
    profile: BmwServiceResetProfile.sl0UdsServiceData,
    ecuKey: 'cuX_BMSMP1',
    delay: (duration) async => delays.add(duration),
  );
  final result = await protocol.execute(
    action: BmwServiceResetAction.all,
    vehicleDateTime: DateTime(2027, 1, 2, 3, 4, 5),
    nextServiceDate: DateTime(2028, 3, 4),
    nextServiceMileage: 0x12345,
  );

  check(
    link.requests.take(3).map((request) => request.join(',')).join('|') ==
        '46,225,43,3,4,5,2,1,7,235|46,225,44,4,3,7,236|46,225,45,35,69',
    'UDS write DIDs, date fields, mileage truncation, or order changed',
  );
  check(
    link.requests.skip(3).map((request) => request.join(',')).join('|') ==
        '34,225,25|34,225,43|34,225,45|34,225,44',
    'Service reset readback request IDs/order changed',
  );
  check(result.writtenDids.join(',') == '57643,57644,57645',
      'Written DID list was not retained');
  check(
      result.odometerKilometers == 12345, 'Odometer readback was not decoded');
  check(result.readback[0xe12b]!.join(',') == '3,4,5,2,1,7,235',
      'Bike clock readback was lost');
  check(
      delays.length == 3 &&
          delays.every(
              (duration) => duration == const Duration(milliseconds: 1500)),
      'Reference 1.5 second post-write delay missing');

  final individualLink = FakeUdsLink();
  final individual = BmwServiceResetProtocol(
    link: individualLink,
    profile: BmwServiceResetProfile.sl0UdsServiceData,
    ecuKey: 'cuX_BMSX',
    delay: (_) async {},
  );
  await individual.execute(
    action: BmwServiceResetAction.nextServiceDate,
    vehicleDateTime: DateTime(2027, 1, 2),
    nextServiceDate: DateTime(2030, 12, 31),
    nextServiceMileage: 10000,
  );
  check(individualLink.requests.first.join(',') == '46,225,44,31,12,7,238',
      'SI_DATE must only write E12C');
  check(
      individualLink.requests
              .where((request) => request.first == 0x2e)
              .length ==
          1,
      'Single reset action issued extra writes');

  final rejectedLink = FakeUdsLink()..rejectWriteDid = 0xe12d;
  final rejected = BmwServiceResetProtocol(
    link: rejectedLink,
    profile: BmwServiceResetProfile.sl0UdsServiceData,
    ecuKey: 'cuX_BMSO1',
    delay: (_) async {},
  );
  try {
    await rejected.execute(
      action: BmwServiceResetAction.nextServiceMileage,
      vehicleDateTime: DateTime(2027),
      nextServiceDate: DateTime(2028),
      nextServiceMileage: 10000,
    );
    throw StateError('Negative ECU write response was accepted');
  } on UdsNegativeResponseException catch (error) {
    check(error.code == 0x31, 'Negative response NRC was not preserved');
  }
  check(
      rejectedLink.requests.length == 1, 'Readback ran after a rejected write');

  final mismatchLink = FakeUdsLink()..mismatchReadbackDid = 0xe12c;
  final mismatch = BmwServiceResetProtocol(
    link: mismatchLink,
    profile: BmwServiceResetProfile.sl0UdsServiceData,
    ecuKey: 'cuX_BMSE2',
    delay: (_) async {},
  );
  try {
    await mismatch.execute(
      action: BmwServiceResetAction.nextServiceDate,
      vehicleDateTime: DateTime(2027),
      nextServiceDate: DateTime(2030, 12, 31),
      nextServiceMileage: 10000,
    );
    throw StateError('Mismatched service-date readback was accepted');
  } on FormatException catch (error) {
    check(error.message.toString().contains('readback'),
        'Mismatched readback was rejected without a useful error');
  }

  final unsupportedLink = FakeUdsLink();
  final unsupported = BmwServiceResetProtocol(
    link: unsupportedLink,
    profile: BmwServiceResetProfile.sl0UdsServiceData,
    ecuKey: 'cuMRBMSMP1', // CF_SERVICE flag exists, but class is KWP/pl0.
    delay: (_) async {},
  );
  try {
    await unsupported.execute(
      action: BmwServiceResetAction.all,
      vehicleDateTime: DateTime(2027),
      nextServiceDate: DateTime(2028),
      nextServiceMileage: 10000,
    );
    throw StateError('KWP/native-only key was accepted by the sl0 UDS handler');
  } on UnsupportedError {
    // Service flag alone is insufficient without a matching sl0 factory path.
  }
  check(unsupportedLink.requests.isEmpty,
      'Unsupported ECU received a service write');

  for (final key in BmwServiceResetCatalog.sl0UdsEcuKeys) {
    check(BmwServiceResetCatalog.supportsEcuKey(key),
        'Recovered sl0 ECU key $key was not enabled');
  }
  for (final key in const [
    'cuX_KOMB18',
    'cuX_BMSMS1',
    'cuX_BMSAE1',
    'cuX_BMSTVS',
  ]) {
    check(!BmwServiceResetCatalog.supportsEcuKey(key),
        'Unsupported or disabled ECU key $key was enabled');
  }

  // ignore: avoid_print
  print(
      'PASS: E12x service reset writes, pacing, positive acknowledgements and readback');
}
