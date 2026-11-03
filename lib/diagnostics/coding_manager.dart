import 'dart:convert';

import 'bmw_coding_engine.dart';

export 'bmw_coding_engine.dart';

/// A customizable coding configuration option.
class CodingOption<T> {
  const CodingOption({
    required this.id,
    required this.title,
    required this.ecuAcronym,
    required this.ecuAddress,
    required this.description,
    required this.values,
    required this.defaultValue,
  });

  final String id;
  final String title;
  final String ecuAcronym;
  final int ecuAddress;
  final String description;
  final List<T> values;
  final T defaultValue;
}

/// A saved coding snapshot for vehicle backup & restore.
class CodingSnapshot {
  CodingSnapshot({
    required this.id,
    required this.timestamp,
    required this.vehicleModel,
    required this.vin,
    required this.values,
    this.sha256Hash,
  });

  final String id;
  final DateTime timestamp;
  final String vehicleModel;
  final String vin;
  final Map<String, dynamic> values;
  final String? sha256Hash;

  String get formattedDate =>
      '${timestamp.year}-${timestamp.month.toString().padLeft(2, '0')}-${timestamp.day.toString().padLeft(2, '0')} ${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';

  Map<String, dynamic> toJson() => {
        'id': id,
        'timestamp': timestamp.toIso8601String(),
        'vehicleModel': vehicleModel,
        'vin': vin,
        'values': values,
        if (sha256Hash != null) 'sha256Hash': sha256Hash,
      };

  factory CodingSnapshot.fromJson(Map<String, dynamic> json) => CodingSnapshot(
        id: json['id'] as String,
        timestamp: DateTime.parse(json['timestamp'] as String),
        vehicleModel: json['vehicleModel'] as String? ?? 'BMW Motorrad',
        vin: json['vin'] as String? ?? 'UNKNOWN',
        values: Map<String, dynamic>.from(json['values'] as Map),
        sha256Hash: json['sha256Hash'] as String?,
      );
}

/// Engine managing BMW Motorrad vehicle coding and configuration backups.
class BmwCodingManager {
  BmwCodingManager({this.catalog}) {
    // Populate verified defaults
    _currentValues = {
      'startup_animation': 'M Motorsport',
      'clock_format': '24h',
      'date_format': 'DD.MM.YYYY',
      'temp_unit': '°C',
      'pressure_unit': 'bar',
      'consumption_unit': 'l/100km',
      'shift_light_rpm': 9500,
      'led_indicators': true,
      'daytime_running_lights': true,
      'auxiliary_fog_lights': false,
      'heated_grips_curve': 'High (Standard)',
    };
  }

  final BmwCodingDefinitionCatalog? catalog;
  late final BmwCodingEngine _engine = BmwCodingEngine(
    catalog: catalog ??
        const BmwCodingDefinitionCatalog(
          variants: {},
          totalVariants: 0,
          totalParameters: 0,
          totalOptions: 0,
        ),
  );

  static const startupAnimationOption = CodingOption<String>(
    id: 'startup_animation',
    title: 'TFT Startup Animation',
    ecuAcronym: 'KOMBI',
    ecuAddress: 0x60,
    description:
        'Select the startup splash animation displayed on the 6.5" Connectivity TFT screen when turning on ignition.',
    values: ['Standard BMW', 'M Motorsport', 'GS Adventure', 'Sport Pro'],
    defaultValue: 'Standard BMW',
  );

  static const clockFormatOption = CodingOption<String>(
    id: 'clock_format',
    title: 'Clock Display Mode',
    ecuAcronym: 'KOMBI',
    ecuAddress: 0x60,
    description: 'Time display formatting on instrument cluster.',
    values: ['24h', '12h (AM/PM)'],
    defaultValue: '24h',
  );

  static const tempUnitOption = CodingOption<String>(
    id: 'temp_unit',
    title: 'Temperature Display Unit',
    ecuAcronym: 'KOMBI',
    ecuAddress: 0x60,
    description: 'Ambient and engine temperature display units on dashboard.',
    values: ['°C', '°F'],
    defaultValue: '°C',
  );

  static const pressureUnitOption = CodingOption<String>(
    id: 'pressure_unit',
    title: 'Tire Pressure Unit (RDC)',
    ecuAcronym: 'KOMBI',
    ecuAddress: 0x60,
    description: 'RDC tire pressure display unit.',
    values: ['bar', 'psi', 'kPa'],
    defaultValue: 'bar',
  );

  static const ledIndicatorsOption = CodingOption<bool>(
    id: 'led_indicators',
    title: 'LED Turn Indicators Retrofit',
    ecuAcronym: 'ZFE',
    ecuAddress: 0x00,
    description:
        'Enables LED indicator pulsing without requiring external load ballast resistors. Eliminates bulb failure warnings.',
    values: [true, false],
    defaultValue: true,
  );

  static const drlOption = CodingOption<bool>(
    id: 'daytime_running_lights',
    title: 'Daytime Running Lights (DRL)',
    ecuAcronym: 'ZFE',
    ecuAddress: 0x00,
    description:
        'Enables automatic headlight halo ring daytime running lights with light sensor auto-switch.',
    values: [true, false],
    defaultValue: true,
  );

  static const auxFogLightsOption = CodingOption<bool>(
    id: 'auxiliary_fog_lights',
    title: 'Auxiliary LED Fog Lights (Nano)',
    ecuAcronym: 'ZFE',
    ecuAddress: 0x00,
    description:
        'Activates BMW original equipment auxiliary LED driving lights and handlebar switch integration.',
    values: [true, false],
    defaultValue: false,
  );

  late Map<String, dynamic> _currentValues;
  final List<CodingSnapshot> _snapshots = [];

  Map<String, dynamic> get currentValues => Map.unmodifiable(_currentValues);
  List<CodingSnapshot> get snapshots => List.unmodifiable(_snapshots);
  BmwCodingEngine get engine => _engine;

  void setValue(String id, dynamic value) {
    _currentValues[id] = value;
  }

  CodingSnapshot createSnapshot({
    required String model,
    required String vin,
    String? sha256Hash,
  }) {
    final snapshot = CodingSnapshot(
      id: 'SNAP_${DateTime.now().millisecondsSinceEpoch}',
      timestamp: DateTime.now(),
      vehicleModel: model,
      vin: vin,
      values: Map<String, dynamic>.from(_currentValues),
      sha256Hash: sha256Hash,
    );
    _snapshots.insert(0, snapshot);
    return snapshot;
  }

  bool restoreSnapshot(String snapshotId) {
    final match = _snapshots.where((s) => s.id == snapshotId).firstOrNull;
    if (match != null) {
      _currentValues = Map<String, dynamic>.from(match.values);
      return true;
    }
    return false;
  }

  String exportToJson() => jsonEncode({
        'values': _currentValues,
        'snapshots': _snapshots.map((s) => s.toJson()).toList(),
      });
}
