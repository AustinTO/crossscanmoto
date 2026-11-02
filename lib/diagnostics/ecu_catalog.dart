import 'package:flutter/material.dart';

import 'recovered_catalog.dart';

/// Categories of BMW Motorrad electronic control units.
enum EcuCategory {
  powertrain,
  chassis,
  cockpit,
  body,
  security,
}

/// Known BMW Motorrad Electronic Control Unit metadata.
class BmwEcuDefinition {
  const BmwEcuDefinition({
    required this.id,
    required this.name,
    required this.germanAbbrev,
    required this.category,
    required this.standardUdsAddress,
    required this.legacyKwpAddress,
    required this.description,
    required this.icon,
    this.candidateEcuKeys = const [],
    this.isLegacyKwp = false,
    this.protocolId = 8,
    this.supportedDids = const [
      0xF190, // VIN
      0xF187, // BMW Part Number
      0xF189, // Software ID
      0xF191, // Hardware ID
      0xF188, // Software Version
      0xF197, // System Supplier / Name
      0xF18C, // Serial Number
    ],
  });

  final String id;
  final String name;
  final String germanAbbrev;
  final EcuCategory category;
  final int standardUdsAddress;
  final int legacyKwpAddress;
  final String description;
  final IconData icon;
  final List<String> candidateEcuKeys;
  final bool isLegacyKwp;
  final int protocolId;
  final List<int> supportedDids;

  String get hexAddress =>
      '0x${standardUdsAddress.toRadixString(16).padLeft(2, '0').toUpperCase()}';

  String get categoryLabel => switch (category) {
        EcuCategory.powertrain => 'Powertrain',
        EcuCategory.chassis => 'Chassis & Brakes',
        EcuCategory.cockpit => 'Cockpit & Display',
        EcuCategory.body => 'Body Electronics',
        EcuCategory.security => 'Security & TPMS',
      };
}

/// Catalog of all BMW Motorrad Electronic Control Units.
class BmwEcuCatalog {
  const BmwEcuCatalog._();

  static const dme = BmwEcuDefinition(
    id: 'dme',
    name: 'Engine Electronics',
    germanAbbrev: 'DME / BMS-K',
    category: EcuCategory.powertrain,
    standardUdsAddress: 0x12,
    legacyKwpAddress: 0x12,
    description:
        'Engine control unit (BMS-K, BMS-KP, BMS-MP, BMS-O, ME17.2). Controls fuel injection, ignition, ShiftCam, ride-by-wire and emissions.',
    icon: Icons.settings_input_component,
    candidateEcuKeys: [
      'cuX_BMSX',
      'cuX_BMSO1',
      'cuX_BMSMP1',
      'cuX_BMSE2B',
      'cuX_BMSE2',
      'cuX_BMSAE1',
      'cuMRBMSMP1',
      'cuMRMA24',
    ],
  );

  static const abs = BmwEcuDefinition(
    id: 'abs',
    name: 'ABS / Dynamic Traction Control',
    germanAbbrev: 'ABS / DTC',
    category: EcuCategory.chassis,
    standardUdsAddress: 0x28,
    legacyKwpAddress: 0x28,
    description:
        'Brake and stability control unit (I-ABS 2, ABS 8M, ABS 9M, ABS Pro). Controls anti-lock braking, cornering ABS, ASC and DTC.',
    icon: Icons.shield_outlined,
    candidateEcuKeys: [
      'cuX_ABS',
      'cuX_ABS9M',
      'cuX_ABSVI',
      'cuMRABS',
    ],
  );

  static const kombi = BmwEcuDefinition(
    id: 'kombi',
    name: 'Instrument Cluster',
    germanAbbrev: 'KOMBI / TFT',
    category: EcuCategory.cockpit,
    standardUdsAddress: 0x60,
    legacyKwpAddress: 0x60,
    description:
        'Instrument cluster and Connectivity TFT display. Manages speedometer, tachometer, on-board computer, service intervals and animations.',
    icon: Icons.speed,
    candidateEcuKeys: [
      'cuX_KOMBI',
      'cuX_KOMB50',
      'cuX_KOMB18',
      'cuX_KOMB17',
      'cuX_KOMB46',
      'cuX_KOMB53',
      'cuX_KOMBB2',
      'cuX_KOMBHI',
      'cuX_KOMBLO',
      'cuX_KOMB_A',
      'cuX_KOMB03',
    ],
  );

  static const zfe = BmwEcuDefinition(
    id: 'zfe',
    name: 'Body Controller / Central Electronics',
    germanAbbrev: 'ZFE / BDC',
    category: EcuCategory.body,
    standardUdsAddress: 0x00,
    legacyKwpAddress: 0x00,
    description:
        'Central chassis electronics module. Manages lights, indicators, horn, grip heating, seat heating and electronic fuses.',
    icon: Icons.electrical_services,
    candidateEcuKeys: [
      'cuX_BCO',
      'cuX_BCA',
      'cuX_BCL',
    ],
  );

  static const ews = BmwEcuDefinition(
    id: 'ews',
    name: 'Electronic Immobilizer / Keyless Ride',
    germanAbbrev: 'EWS / KLR',
    category: EcuCategory.security,
    standardUdsAddress: 0x24,
    legacyKwpAddress: 0x24,
    description:
        'Electronic immobilizer and Keyless Ride controller. Authenticates transponder keys and unlocks steering and fuel filler.',
    icon: Icons.vpn_key_outlined,
    candidateEcuKeys: [
      'cuX_EWS4',
    ],
  );

  static const rdc = BmwEcuDefinition(
    id: 'rdc',
    name: 'Tire Pressure Control',
    germanAbbrev: 'RDC / TPMS',
    category: EcuCategory.security,
    standardUdsAddress: 0x39,
    legacyKwpAddress: 0x39,
    description:
        'Tire pressure monitoring system. Receives wireless wheel sensor telegrams for front and rear pressure and temperature.',
    icon: Icons.tire_repair,
    candidateEcuKeys: [
      'cuX_RDC',
      'cuMRRDC',
      'cuX_TPM',
      'cuX_TPM4G',
    ],
  );

  static const esa = BmwEcuDefinition(
    id: 'esa',
    name: 'Dynamic ESA / Suspension',
    germanAbbrev: 'SAF / D-ESA',
    category: EcuCategory.chassis,
    standardUdsAddress: 0x58,
    legacyKwpAddress: 0x58,
    description:
        'Semi-active electronic suspension controller. Regulates spring preload stepper and dynamic damping valves according to ride modes.',
    icon: Icons.airline_seat_recline_extra_outlined,
    candidateEcuKeys: [
      'cuX_ESA',
      'cuX_SAF',
    ],
  );

  static const dwa = BmwEcuDefinition(
    id: 'dwa',
    name: 'Anti-Theft Alarm System',
    germanAbbrev: 'DWA',
    category: EcuCategory.security,
    standardUdsAddress: 0x62,
    legacyKwpAddress: 0x62,
    description:
        'Anti-theft alarm control unit with tilt and motion sensors, siren and RF remote receiver.',
    icon: Icons.notifications_active_outlined,
    candidateEcuKeys: [
      'cuX_DWA',
      'cuX_DWA_9',
      'cuMRDWA',
    ],
  );

  static const rad = BmwEcuDefinition(
    id: 'rad',
    name: 'Audio System / Radio',
    germanAbbrev: 'RAD',
    category: EcuCategory.cockpit,
    standardUdsAddress: 0x68,
    legacyKwpAddress: 0x68,
    description:
        'Motorcycle audio system and Bluetooth audio receiver (touring models: R 1250 RT, K 1600 GT/GTL).',
    icon: Icons.radio_outlined,
    candidateEcuKeys: [
      'cuX_AUDIO',
    ],
  );

  static const all = <BmwEcuDefinition>[
    dme,
    abs,
    kombi,
    zfe,
    ews,
    rdc,
    esa,
    dwa,
    rad,
  ];

  static BmwEcuDefinition? getByAddress(int address) {
    for (final ecu in all) {
      if (ecu.standardUdsAddress == address || ecu.legacyKwpAddress == address) {
        return ecu;
      }
    }
    return null;
  }

  static BmwEcuDefinition? getById(String id) {
    for (final ecu in all) {
      if (ecu.id == id) return ecu;
    }
    return null;
  }

  /// Resolves the authentic control units for a given motorcycle model or series code
  /// based on the recovered platform routing tables from MotoScan native data.
  static List<BmwEcuDefinition> forSeries(String seriesCode) {
    final groups = BmwRawVehicleDatabase.groupsForSeries(seriesCode);
    if (groups.isEmpty) {
      return all;
    }
    return forGroups(groups);
  }

  /// Maps recovered native ECU groups to rich BmwEcuDefinition objects.
  static List<BmwEcuDefinition> forGroups(List<Map<String, String>> groups) {
    final definitions = <BmwEcuDefinition>[];
    for (final group in groups) {
      final type = group['controlmoduletype']?.toUpperCase() ?? 'ECU';
      final addr = int.tryParse(group['defaultaddress'] ?? '') ?? 0x12;
      final protoId = int.tryParse(group['defaultprotocolid'] ?? '') ?? 8;
      final isKwp = protoId == 3;
      final modGroup = group['modulegroup'] ?? '';

      final (category, icon, friendlyName, description) = _metadataForType(type);
      final candidateKeys = _candidateKeysForType(type, isKwp: isKwp);

      definitions.add(BmwEcuDefinition(
        id: '${type.toLowerCase()}_0x${addr.toRadixString(16)}',
        name: friendlyName,
        germanAbbrev: type,
        category: category,
        standardUdsAddress: addr,
        legacyKwpAddress: addr,
        description: description.isNotEmpty
            ? description
            : 'BMW Motorrad $type control unit ($modGroup) at address 0x${addr.toRadixString(16).padLeft(2, '0').toUpperCase()} via ${isKwp ? "KWP2000" : "UDS"}.',
        icon: icon,
        isLegacyKwp: isKwp,
        protocolId: protoId,
        candidateEcuKeys: candidateKeys,
      ));
    }

    // Sort powertrain/engine ECUs first, followed by lower addresses for deterministic scanning order
    definitions.sort((a, b) {
      final aPowertrain = a.category == EcuCategory.powertrain ? 0 : 1;
      final bPowertrain = b.category == EcuCategory.powertrain ? 0 : 1;
      if (aPowertrain != bPowertrain) return aPowertrain.compareTo(bPowertrain);
      return a.standardUdsAddress.compareTo(b.standardUdsAddress);
    });

    return List.unmodifiable(definitions);
  }

  static (EcuCategory, IconData, String, String) _metadataForType(String type) {
    switch (type.toUpperCase()) {
      case 'DME':
      case 'BMS':
      case 'BMS-K':
      case 'BMS-O':
      case 'BMS-X':
      case 'BMS-MP':
        return (
          EcuCategory.powertrain,
          Icons.settings_input_component,
          'Engine Electronics',
          'Engine control unit (DME/BMS). Controls fuel injection, ignition, ShiftCam, ride-by-wire and emissions.',
        );
      case 'ABS':
      case 'DTC':
        return (
          EcuCategory.chassis,
          Icons.shield_outlined,
          'ABS / Traction Control',
          'Anti-lock braking and stability control unit (I-ABS, ABS 9M, ABS Pro).',
        );
      case 'KOMBI':
      case 'TFT':
        return (
          EcuCategory.cockpit,
          Icons.speed,
          'Instrument Cluster',
          'Instrument cluster and display unit (KOMBI / TFT). Displays speed, telemetry, warnings and service intervals.',
        );
      case 'ZFE':
      case 'GM':
      case 'BCO':
        return (
          EcuCategory.body,
          Icons.electrical_services,
          'Central Vehicle Electronics',
          'Central body electronics control unit (ZFE / GM / BCO). Controls lighting, switches, horn and bus routing.',
        );
      case 'RDC':
      case 'TPM':
      case 'TM':
        return (
          EcuCategory.security,
          Icons.tire_repair,
          'Tire Pressure Monitor (RDC)',
          'Tire pressure monitoring system. Reads wheel sensor pressures and battery states.',
        );
      case 'DWA':
        return (
          EcuCategory.security,
          Icons.lock_outline,
          'Anti-Theft Alarm (DWA)',
          'Anti-theft alarm and immobilizer system (DWA). Monitors tilt sensors and remote keys.',
        );
      case 'ESA':
      case 'DDC':
      case 'SAF':
        return (
          EcuCategory.chassis,
          Icons.tune,
          'Electronic Suspension (ESA / DDC)',
          'Dynamic suspension and damping control unit (ESA / DDC). Controls preload and rebound.',
        );
      case 'AUDIO':
      case 'AUD':
        return (
          EcuCategory.cockpit,
          Icons.volume_up,
          'Audio System',
          'On-board audio and entertainment system. Controls speakers, radio, and external inputs.',
        );
      case 'ACC':
        return (
          EcuCategory.chassis,
          Icons.radar,
          'Active Cruise Control (ACC)',
          'Front radar-based active cruise control unit (ACC).',
        );
      case 'ZGW':
        return (
          EcuCategory.body,
          Icons.router,
          'Central Gateway (ZGW)',
          'Central vehicle gateway connecting CAN, LIN, and Ethernet diagnostic buses.',
        );
      case 'EWS':
      case 'SLZ':
        return (
          EcuCategory.security,
          Icons.vpn_key,
          'Electronic Immobilizer (EWS / Keyless)',
          'Keyless ride and electronic immobilizer steering lock system (SLZ / EWS).',
        );
      case 'SVA':
        return (
          EcuCategory.cockpit,
          Icons.visibility,
          'Side View Assist (SVA)',
          'Side blind-spot detection and warning sensors.',
        );
      default:
        return (
          EcuCategory.body,
          Icons.memory,
          'Control Unit ($type)',
          'BMW Motorrad $type electronic control module.',
        );
    }
  }

  static List<String> _candidateKeysForType(String type, {required bool isKwp}) {
    switch (type.toUpperCase()) {
      case 'DME':
      case 'BMS':
        return isKwp
            ? ['cuMRBMSMP1', 'cuMRMA24']
            : ['cuX_BMSX', 'cuX_BMSO1', 'cuX_BMSMP1', 'cuX_BMSE2B', 'cuX_BMSE2', 'cuX_BMSAE1'];
      case 'ABS':
        return isKwp
            ? ['cuMRABS']
            : ['cuX_ABS', 'cuX_ABS9M', 'cuX_ABSVI'];
      case 'KOMBI':
        return isKwp
            ? ['cuMRKOMB18', 'cuMRKOMB46']
            : ['cuX_KOMBI', 'cuX_KOMB50', 'cuX_KOMB18', 'cuX_KOMB17', 'cuX_KOMB46', 'cuX_KOMB53', 'cuX_KOMBB2', 'cuX_KOMBHI'];
      case 'ZFE':
      case 'GM':
        return isKwp ? ['cuMRZFE'] : ['cuX_BCO', 'cuX_ZFE'];
      case 'RDC':
      case 'TPM':
      case 'TM':
        return isKwp ? ['cuMRRDC'] : ['cuX_RDC', 'cuX_TPM'];
      case 'DWA':
        return isKwp ? ['cuMRDWA'] : ['cuX_DWA'];
      case 'AUDIO':
      case 'AUD':
        return isKwp ? ['cuMRAUD'] : ['cuX_AUDIO'];
      case 'EWS':
      case 'SLZ':
        return isKwp ? ['cuMREWS'] : ['cuX_SLZ', 'cuX_EWS'];
      case 'ESA':
      case 'DDC':
        return isKwp ? ['cuMRESA'] : ['cuX_SAF', 'cuX_DDC', 'cuX_ESA'];
      default:
        return const [];
    }
  }
}
