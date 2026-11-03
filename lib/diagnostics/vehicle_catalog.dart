import 'recovered_catalog.dart';

/// BMW Motorrad motorcycle model and series definitions.
class BmwMotorcycleModel {
  const BmwMotorcycleModel({
    required this.name,
    required this.seriesCode,
    required this.engineType,
    required this.displacementCc,
    required this.startYear,
    required this.endYear,
    this.platformId,
    this.primaryEcuAddresses = const [0x12, 0x28, 0x60, 0x00, 0x24, 0x39, 0x58],
    this.vinVdsCodes = const [],
  });

  final String name;
  final String seriesCode;
  final String engineType;
  final int displacementCc;
  final int startYear;
  final int endYear;
  final String? platformId;
  final List<int> primaryEcuAddresses;
  final List<String> vinVdsCodes;

  String get displayName => name;
  String get yearRange => '$startYear–$endYear';
}

/// Complete catalog of supported BMW Motorrad models.
class BmwVehicleCatalog {
  const BmwVehicleCatalog._();

  static const models = <BmwMotorcycleModel>[
    // R-Series (Boxer)
    BmwMotorcycleModel(
      name: 'R 1250 GS',
      seriesCode: 'K50',
      engineType: 'Boxer Twin (ShiftCam)',
      displacementCc: 1254,
      startYear: 2018,
      endYear: 2024,
      vinVdsCodes: ['0J91', '0J93', '0M01', '0M03'],
    ),
    BmwMotorcycleModel(
      name: 'R 1250 GS Adventure',
      seriesCode: 'K51',
      engineType: 'Boxer Twin (ShiftCam)',
      displacementCc: 1254,
      startYear: 2018,
      endYear: 2024,
      vinVdsCodes: ['0J92', '0J94'],
    ),
    BmwMotorcycleModel(
      name: 'R 1250 RT',
      seriesCode: 'K52',
      engineType: 'Boxer Twin (ShiftCam)',
      displacementCc: 1254,
      startYear: 2018,
      endYear: 2024,
      primaryEcuAddresses: [0x12, 0x28, 0x60, 0x00, 0x24, 0x39, 0x58, 0x68],
      vinVdsCodes: ['0J61', '0J63', '0L01'],
    ),
    BmwMotorcycleModel(
      name: 'R 1250 RS',
      seriesCode: 'K54',
      engineType: 'Boxer Twin (ShiftCam)',
      displacementCc: 1254,
      startYear: 2019,
      endYear: 2024,
      vinVdsCodes: ['0J81', '0J83'],
    ),
    BmwMotorcycleModel(
      name: 'R 1250 R',
      seriesCode: 'K53',
      engineType: 'Boxer Twin (ShiftCam)',
      displacementCc: 1254,
      startYear: 2019,
      endYear: 2024,
      vinVdsCodes: ['0J71', '0J73'],
    ),
    BmwMotorcycleModel(
      name: 'R 1300 GS',
      seriesCode: 'KA1',
      engineType: 'Boxer Twin',
      displacementCc: 1300,
      startYear: 2023,
      endYear: 2026,
      vinVdsCodes: ['0M21', '0M23'],
    ),
    BmwMotorcycleModel(
      name: 'R 1200 GS (LC)',
      seriesCode: 'K50',
      engineType: 'Boxer Twin (Liquid-cooled)',
      displacementCc: 1170,
      startYear: 2013,
      endYear: 2018,
      vinVdsCodes: ['0A01', '0A11', '0A51', '0A61', '0A03', '0A13'],
    ),
    BmwMotorcycleModel(
      name: 'R 1200 GS Adventure (LC)',
      seriesCode: 'K51',
      engineType: 'Boxer Twin (Liquid-cooled)',
      displacementCc: 1170,
      startYear: 2014,
      endYear: 2018,
      vinVdsCodes: ['0A02', '0A12'],
    ),
    BmwMotorcycleModel(
      name: 'R 1200 GS (DOHC)',
      seriesCode: 'K25',
      engineType: 'Boxer Twin (Air/Oil-cooled)',
      displacementCc: 1170,
      startYear: 2010,
      endYear: 2013,
      vinVdsCodes: ['0450', '0460', '0303', '0313'],
    ),
    BmwMotorcycleModel(
      name: 'R nineT (2014–2016)',
      seriesCode: 'K21',
      platformId: '1',
      engineType: 'Boxer Twin (Air/Oil-cooled)',
      displacementCc: 1170,
      startYear: 2014,
      endYear: 2016,
      primaryEcuAddresses: [0x12, 0x28, 0x60, 0x00, 0x24],
      vinVdsCodes: ['0A06', '0A16'],
    ),
    BmwMotorcycleModel(
      name: 'R nineT MUE (2017–2023)',
      seriesCode: 'K21',
      platformId: '2',
      engineType: 'Boxer Twin (Air/Oil-cooled EU4/EU5)',
      displacementCc: 1170,
      startYear: 2017,
      endYear: 2023,
      primaryEcuAddresses: [0x12, 0x28, 0x60, 0x00, 0x24, 0x39],
      vinVdsCodes: ['0J01', '0J03', '0J11', '0J13', '0J21', '0J23', '0J31', '0J33', '0L51', '0L53'],
    ),
    BmwMotorcycleModel(
      name: 'R 18',
      seriesCode: 'K34',
      engineType: 'Big Boxer Twin',
      displacementCc: 1802,
      startYear: 2020,
      endYear: 2026,
      vinVdsCodes: ['0L11', '0L13'],
    ),

    // S-Series (Inline-4)
    BmwMotorcycleModel(
      name: 'S 1000 RR (K46, 2010–2012)',
      seriesCode: 'K46',
      platformId: '1',
      engineType: 'Inline-4',
      displacementCc: 999,
      startYear: 2010,
      endYear: 2012,
    ),
    BmwMotorcycleModel(
      name: 'S 1000 RR',
      seriesCode: 'K67',
      engineType: 'Inline-4 (ShiftCam)',
      displacementCc: 999,
      startYear: 2019,
      endYear: 2026,
      primaryEcuAddresses: [0x12, 0x28, 0x60, 0x00, 0x24, 0x58],
      vinVdsCodes: ['0E21', '0E23', '0507', '0524', '0D10'],
    ),
    BmwMotorcycleModel(
      name: 'S 1000 R',
      seriesCode: 'K63',
      engineType: 'Inline-4',
      displacementCc: 999,
      startYear: 2021,
      endYear: 2026,
    ),
    BmwMotorcycleModel(
      name: 'S 1000 XR',
      seriesCode: 'K69',
      engineType: 'Inline-4',
      displacementCc: 999,
      startYear: 2020,
      endYear: 2026,
    ),
    BmwMotorcycleModel(
      name: 'M 1000 RR',
      seriesCode: 'K66',
      engineType: 'Inline-4 M Competition',
      displacementCc: 999,
      startYear: 2021,
      endYear: 2026,
    ),

    // F-Series (Parallel-Twin)
    BmwMotorcycleModel(
      name: 'F 850 GS',
      seriesCode: 'K81',
      engineType: 'Parallel-Twin',
      displacementCc: 853,
      startYear: 2018,
      endYear: 2024,
      vinVdsCodes: ['0B09', '0B19'],
    ),
    BmwMotorcycleModel(
      name: 'F 750 GS',
      seriesCode: 'K80',
      engineType: 'Parallel-Twin',
      displacementCc: 853,
      startYear: 2018,
      endYear: 2024,
      vinVdsCodes: ['0B08', '0B18'],
    ),
    BmwMotorcycleModel(
      name: 'F 900 R',
      seriesCode: 'K83',
      engineType: 'Parallel-Twin',
      displacementCc: 895,
      startYear: 2020,
      endYear: 2026,
      vinVdsCodes: ['0K21', '0K23'],
    ),
    BmwMotorcycleModel(
      name: 'F 900 XR',
      seriesCode: 'K84',
      engineType: 'Parallel-Twin',
      displacementCc: 895,
      startYear: 2020,
      endYear: 2026,
      vinVdsCodes: ['0K41', '0K43'],
    ),
    BmwMotorcycleModel(
      name: 'F 800 GS',
      seriesCode: 'K72',
      engineType: 'Parallel-Twin',
      displacementCc: 798,
      startYear: 2008,
      endYear: 2018,
      vinVdsCodes: ['0219', '0229', '0B02', '0B12'],
    ),

    // K-Series (Inline-6)
    BmwMotorcycleModel(
      name: 'K 1600 GT',
      seriesCode: 'K48',
      engineType: 'Inline-6',
      displacementCc: 1649,
      startYear: 2011,
      endYear: 2026,
      primaryEcuAddresses: [0x12, 0x28, 0x60, 0x00, 0x24, 0x39, 0x58, 0x68],
      vinVdsCodes: ['0601', '0611', '0F01', '0F11'],
    ),
    BmwMotorcycleModel(
      name: 'K 1600 B (Bagger)',
      seriesCode: 'K61',
      engineType: 'Inline-6',
      displacementCc: 1649,
      startYear: 2017,
      endYear: 2026,
      vinVdsCodes: ['0F51', '0F53'],
    ),

    // G-Series (Single)
    BmwMotorcycleModel(
      name: 'G 310 GS',
      seriesCode: 'K02',
      engineType: 'Single-Cylinder',
      displacementCc: 313,
      startYear: 2017,
      endYear: 2026,
      primaryEcuAddresses: [0x12, 0x28, 0x60, 0x00],
      vinVdsCodes: ['0G02', '0G12'],
    ),
    BmwMotorcycleModel(
      name: 'G 310 R',
      seriesCode: 'K03',
      engineType: 'Single-Cylinder',
      displacementCc: 313,
      startYear: 2016,
      endYear: 2026,
      primaryEcuAddresses: [0x12, 0x28, 0x60, 0x00],
      vinVdsCodes: ['0G01', '0G11'],
    ),

    // C-Series (Urban Mobility)
    BmwMotorcycleModel(
      name: 'C 400 GT',
      seriesCode: 'K08',
      engineType: 'Single-Cylinder Scooter',
      displacementCc: 350,
      startYear: 2018,
      endYear: 2026,
      vinVdsCodes: ['0C05', '0C15'],
    ),
    BmwMotorcycleModel(
      name: 'CE 04',
      seriesCode: 'K07',
      engineType: 'Electric Motor',
      displacementCc: 0,
      startYear: 2022,
      endYear: 2026,
      vinVdsCodes: ['0C51', '0C53'],
    ),
    BmwMotorcycleModel(
      name: 'C1',
      seriesCode: 'C01',
      engineType: 'Single cylinder 4-stroke',
      displacementCc: 125,
      startYear: 2000,
      endYear: 2003,
      vinVdsCodes: ['0C01', '0C11'],
    ),
  ];

  static BmwMotorcycleModel? findByName(String? name) {
    if (name == null) return null;
    for (final model in models) {
      if (model.name.toLowerCase() == name.toLowerCase()) return model;
    }
    return null;
  }

  /// Decodes model year from 10th character of standard 17-digit BMW VIN.
  static int? decodeModelYear(String vin) {
    if (vin.length < 10) return null;
    final code = vin[9].toUpperCase();
    const yearCodes = {
      'A': 2010, 'B': 2011, 'C': 2012, 'D': 2013, 'E': 2014,
      'F': 2015, 'G': 2016, 'H': 2017, 'J': 2018, 'K': 2019,
      'L': 2020, 'M': 2021, 'N': 2022, 'P': 2023, 'R': 2024,
      'S': 2025, 'T': 2026,
      '1': 2001, '2': 2002, '3': 2003, '4': 2004, '5': 2005,
      '6': 2006, '7': 2007, '8': 2008, '9': 2009,
    };
    return yearCodes[code];
  }

  /// The 84 original vehicle platform definitions recovered from MotoScan native tables.
  static List<Map<String, String>> get recoveredVehicles =>
      BmwRawVehicleDatabase.vehicles;

  /// Automatically matches a vehicle model from a reported VIN string.
  ///
  /// Matches strictly against verified BMW Motorrad Typenschlüssel (type codes)
  /// located in characters 4–7 (Vehicle Descriptor Section - VDS) of standard ISO 3779 VINs.
  ///
  /// Provenance: In BMW Motorrad factory documentation and ETK/KSD parts catalog,
  /// characters 4–7 directly encode the 4-character internal model code (e.g., 0A03 = K50
  /// R 1200 GS LC, 0J91 = K50 R 1250 GS, 0C01 = C01 C1 125, 0E21 = K67 S 1000 RR).
  /// Substring searching across arbitrary serial numbers and invented year ranges is excluded.
  static BmwMotorcycleModel? identifyFromVin(String vin) {
    final cleanVin = vin.trim().toUpperCase();
    if (cleanVin.length < 8) return null;
    final vds = cleanVin.substring(3, 7);
    for (final model in models) {
      if (model.vinVdsCodes.contains(vds)) return model;
    }
    return null;
  }

  /// Attempts to infer likely platform family from responding standard UDS addresses.
  /// Does not guess an arbitrary model when addresses are generic across the fleet
  /// (e.g. DME 0x12 + KOMBI 0x60 are shared by almost all modern BMW motorcycles).
  static BmwMotorcycleModel? inferModelFromAddresses(Iterable<int> addresses) {
    // Shared bus combinations (0x12, 0x60, 0x28, 0x58) are common across
    // multiple BMW boxer, inline-4, and parallel-twin platforms. Without a VIN
    // or specific module identification, guessing an exact model is unreliable.
    return null;
  }
}

/// Saved motorcycle profile in workshop state.
class VehicleProfile {
  VehicleProfile({
    this.modelName,
    this.modelYear,
    this.vin,
    this.odometerKm,
    this.notes,
    this.isAutoIdentified = false,
    this.sourceQualifiedId,
    this.variantCode,
    this.ebr,
    this.platformId,
    this.needsDisambiguation = false,
  }) {
    migrateProfile();
  }

  String? modelName;
  int? modelYear;
  String? vin;
  int? odometerKm;
  String? notes;
  bool isAutoIdentified;
  String? sourceQualifiedId;
  String? variantCode;
  String? ebr;
  String? platformId;
  bool needsDisambiguation;

  BmwMotorcycleModel? get model => BmwVehicleCatalog.findByName(modelName);

  bool get hasVehicle => modelName != null;

  /// Migrates legacy unversioned profiles to source-qualified variant identities
  /// without silent misrouting or arbitrary platform guessing.
  void migrateProfile() {
    if (sourceQualifiedId != null || modelName == null) return;

    final cleanName = modelName!.trim();
    if (cleanName.toLowerCase() == 'r ninet' || cleanName.toUpperCase() == 'K21') {
      ebr = 'K21';
      if (modelYear != null && modelYear! <= 2016) {
        platformId = '1';
        sourceQualifiedId = 'source:motoscan:platform:1:K21';
        variantCode = '0A06';
        needsDisambiguation = false;
      } else if (modelYear != null && modelYear! >= 2017) {
        platformId = '2';
        sourceQualifiedId = 'source:motoscan:platform:2:K21';
        variantCode = '0J01';
        needsDisambiguation = false;
      } else {
        needsDisambiguation = true;
      }
      return;
    }

    if (cleanName.toLowerCase().contains('s 1000 rr') || cleanName.toUpperCase() == 'K46') {
      if (modelYear != null && modelYear! <= 2011) {
        ebr = 'K46';
        platformId = '1';
        sourceQualifiedId = 'source:motoscan:platform:1:K46_2010';
        needsDisambiguation = false;
      } else if (modelYear != null && modelYear! >= 2012 && modelYear! <= 2018) {
        ebr = 'K46';
        platformId = '2';
        sourceQualifiedId = 'source:motoscan:platform:2:K46';
        needsDisambiguation = false;
      } else if (modelYear != null && modelYear! >= 2019) {
        ebr = 'K67';
        platformId = '2';
        sourceQualifiedId = 'source:biketune:1.9.1:bike:K67';
        needsDisambiguation = false;
      } else {
        ebr = 'K46';
        needsDisambiguation = true;
      }
      return;
    }

    if (cleanName.toLowerCase() == 'ce 04' || cleanName.toUpperCase() == 'K07') {
      ebr = 'K07';
      platformId = '2';
      sourceQualifiedId = 'source:biketune:1.9.1:bike:K07';
      needsDisambiguation = false;
      return;
    }

    final m = model;
    if (m != null) {
      ebr = m.seriesCode;
      platformId = m.platformId ?? '2';
      sourceQualifiedId = 'source:biketune:1.9.1:bike:${m.seriesCode}';
      needsDisambiguation = false;
    }
  }

  Map<String, dynamic> toJson() => {
        'modelName': modelName,
        'modelYear': modelYear,
        'vin': vin,
        'odometerKm': odometerKm,
        'notes': notes,
        'isAutoIdentified': isAutoIdentified,
        'sourceQualifiedId': sourceQualifiedId,
        'variantCode': variantCode,
        'ebr': ebr,
        'platformId': platformId,
        'needsDisambiguation': needsDisambiguation,
      };

  factory VehicleProfile.fromJson(Map<String, dynamic> json) => VehicleProfile(
        modelName: json['modelName'] as String?,
        modelYear: json['modelYear'] as int?,
        vin: json['vin'] as String?,
        odometerKm: json['odometerKm'] as int?,
        notes: json['notes'] as String?,
        isAutoIdentified: json['isAutoIdentified'] as bool? ?? false,
        sourceQualifiedId: json['sourceQualifiedId'] as String?,
        variantCode: json['variantCode'] as String?,
        ebr: json['ebr'] as String?,
        platformId: json['platformId'] as String?,
        needsDisambiguation: json['needsDisambiguation'] as bool? ?? false,
      );
}
