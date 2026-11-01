import 'elm_session.dart';

enum AdapterVendor { wgSoft, obdLink, other, unknown }

/// Read only adapter identity data. Optional command responses are retained
/// verbatim, including `?`/`ERROR` replies from unsupported commands.
class AdapterProfile {
  const AdapterProfile({
    required this.ati,
    required this.vendor,
    this.atHash1,
    this.atAt1,
    this.stdi,
  });

  final AdapterResponse ati;
  final AdapterVendor vendor;
  final AdapterResponse? atHash1;
  final AdapterResponse? atAt1;
  final AdapterResponse? stdi;

  String get vendorLabel => switch (vendor) {
        AdapterVendor.wgSoft => 'WGSoft',
        AdapterVendor.obdLink => 'OBDLink',
        AdapterVendor.other => 'Other adapter',
        AdapterVendor.unknown => 'Unknown adapter',
      };
}

class AdapterInitialization {
  const AdapterInitialization({
    required this.resetResponses,
    required this.profile,
    required this.voltage,
  });

  final List<AdapterResponse> resetResponses;
  final AdapterProfile profile;
  final AdapterResponse voltage;
}

/// Runs the common reset and initialization sequence for ELM327-compatible OBD interfaces.
///
/// Sends warm-start reset and configures linefeeds, automatic protocol detection,
/// CAN header display, echo, and spaces.
Future<List<AdapterResponse>> initializeCommonAdapter(
    ElmSession session) async {
  const commands = <String>[
    'ATWS', // Initial warm-start reset.
    'ATWS',
    'ATL0',
    'ATSP0',
    'ATH1',
    'ATE0',
    'ATS0',
  ];
  final responses = <AdapterResponse>[];
  for (final command in commands.take(1)) {
    responses.add(await session.command(command));
  }
  for (final command in commands.skip(1)) {
    var response = await session.command(command);
    responses.add(response);
    if (!_initializationSucceeded(command, response)) {
      response = await session.command(command);
      responses.add(response);
      if (!_initializationSucceeded(command, response)) {
        throw StateError('Adapter rejected initialization command $command');
      }
    }
  }
  return List.unmodifiable(responses);
}

/// Complete adapter initialization in the observed VciELM327 order, including
/// profile identification and the four-second post-init settle phase. The
/// default delay matches q()'s observed 2 s ATRV point and 4 s completion; an
/// injected delay lets standalone checks verify ordering without sleeping.
Future<AdapterInitialization> initializeAdapter(
  ElmSession session, {
  Future<void> Function(Duration) delay = _defaultDelay,
}) async {
  final resetResponses = await initializeCommonAdapter(session);
  final profile = await identifyAdapter(session);
  await delay(const Duration(seconds: 2));
  final voltage = await session.command('ATRV');
  await delay(const Duration(seconds: 2));
  return AdapterInitialization(
    resetResponses: resetResponses,
    profile: profile,
    voltage: voltage,
  );
}

/// Queries adapter identification and firmware version commands.
///
/// ATI is the core compatibility check: confirms standard ELM327 command set support.
Future<AdapterProfile> identifyAdapter(ElmSession session) async {
  final ati = await session.command('ATI');
  if (ati.isError || ati.lines.isEmpty || !_contains(ati.text, 'ELM32')) {
    return AdapterProfile(ati: ati, vendor: AdapterVendor.unknown);
  }

  final atHash1 = await session.command('AT#1');
  if (_contains(atHash1.text, 'WGSoft')) {
    return AdapterProfile(
      ati: ati,
      vendor: AdapterVendor.wgSoft,
      atHash1: atHash1,
      atAt1: await session.command('AT@1'),
    );
  }

  final stdi = await session.command('STDI');
  final stdiText = stdi.text;
  final isObdLink = _contains(stdiText, 'OBDLink');
  final atAt1 = await session.command('AT@1');

  return AdapterProfile(
    ati: ati,
    vendor: isObdLink ? AdapterVendor.obdLink : AdapterVendor.other,
    atHash1: atHash1,
    atAt1: atAt1,
    stdi: stdi,
  );
}

bool _contains(String haystack, String needle) =>
    haystack.toLowerCase().contains(needle.toLowerCase());

bool _initializationSucceeded(String command, AdapterResponse response) =>
    command == 'ATWS'
        ? response.lines.any((line) => line.contains('ELM32'))
        : response.lines.any((line) => line.contains('OK'));

Future<void> _defaultDelay(Duration duration) => Future<void>.delayed(duration);
