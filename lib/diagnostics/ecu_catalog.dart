import 'package:flutter/material.dart';

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
}
