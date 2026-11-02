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
    this.primaryEcuAddresses = const [0x12, 0x28, 0x60, 0x00, 0x24, 0x39, 0x58],
    this.vinVdsCodes = const [],
  });

  final String name;
  final String seriesCode;
  final String engineType;
  final int displacementCc;
  final int startYear;
  final int endYear;
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
    ),
    BmwMotorcycleModel(
      name: 'R 1250 RS',
      seriesCode: 'K54',
      engineType: 'Boxer Twin (ShiftCam)',
      displacementCc: 1254,
      startYear: 2019,
      endYear: 2024,
    ),
    BmwMotorcycleModel(
      name: 'R 1250 R',
      seriesCode: 'K53',
      engineType: 'Boxer Twin (ShiftCam)',
      displacementCc: 1254,
      startYear: 2019,
      endYear: 2024,
    ),
    BmwMotorcycleModel(
      name: 'R 1300 GS',
      seriesCode: 'KA1',
      engineType: 'Boxer Twin',
      displacementCc: 1300,
      startYear: 2023,
      endYear: 2026,
    ),
    BmwMotorcycleModel(
      name: 'R 1200 GS (LC)',
      seriesCode: 'K50',
      engineType: 'Boxer Twin (Liquid-cooled)',
      displacementCc: 1170,
      startYear: 2013,
      endYear: 2018,
    ),
    BmwMotorcycleModel(
      name: 'R 1200 GS Adventure (LC)',
      seriesCode: 'K51',
      engineType: 'Boxer Twin (Liquid-cooled)',
      displacementCc: 1170,
      startYear: 2014,
      endYear: 2018,
    ),
    BmwMotorcycleModel(
      name: 'R 1200 GS (DOHC)',
      seriesCode: 'K25',
      engineType: 'Boxer Twin (Air/Oil-cooled)',
      displacementCc: 1170,
      startYear: 2010,
      endYear: 2013,
    ),
    BmwMotorcycleModel(
      name: 'R nineT',
      seriesCode: 'K21',
      engineType: 'Boxer Twin (Air/Oil-cooled)',
      displacementCc: 1170,
      startYear: 2014,
      endYear: 2024,
      primaryEcuAddresses: [0x12, 0x28, 0x60, 0x00, 0x24],
    ),
    BmwMotorcycleModel(
      name: 'R 18',
      seriesCode: 'K34',
      engineType: 'Big Boxer Twin',
      displacementCc: 1802,
      startYear: 2020,
      endYear: 2026,
    ),

    // S-Series (Inline-4)
    BmwMotorcycleModel(
      name: 'S 1000 RR',
      seriesCode: 'K67',
      engineType: 'Inline-4 (ShiftCam)',
      displacementCc: 999,
      startYear: 2019,
      endYear: 2026,
      primaryEcuAddresses: [0x12, 0x28, 0x60, 0x00, 0x24, 0x58],
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
    ),
    BmwMotorcycleModel(
      name: 'F 750 GS',
      seriesCode: 'K80',
      engineType: 'Parallel-Twin',
      displacementCc: 853,
      startYear: 2018,
      endYear: 2024,
    ),
    BmwMotorcycleModel(
      name: 'F 900 R',
      seriesCode: 'K83',
      engineType: 'Parallel-Twin',
      displacementCc: 895,
      startYear: 2020,
      endYear: 2026,
    ),
    BmwMotorcycleModel(
      name: 'F 900 XR',
      seriesCode: 'K84',
      engineType: 'Parallel-Twin',
      displacementCc: 895,
      startYear: 2020,
      endYear: 2026,
    ),
    BmwMotorcycleModel(
      name: 'F 800 GS',
      seriesCode: 'K72',
      engineType: 'Parallel-Twin',
      displacementCc: 798,
      startYear: 2008,
      endYear: 2018,
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
    ),
    BmwMotorcycleModel(
      name: 'K 1600 B (Bagger)',
      seriesCode: 'K61',
      engineType: 'Inline-6',
      displacementCc: 1649,
      startYear: 2017,
      endYear: 2026,
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
    ),
    BmwMotorcycleModel(
      name: 'G 310 R',
      seriesCode: 'K03',
      engineType: 'Single-Cylinder',
      displacementCc: 313,
      startYear: 2016,
      endYear: 2026,
      primaryEcuAddresses: [0x12, 0x28, 0x60, 0x00],
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
      seriesCode: 'K09',
      engineType: 'Electric Motor',
      displacementCc: 0,
      startYear: 2022,
      endYear: 2026,
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
  /// Matches strictly against known VDS codes (characters 4-7) of defined models,
  /// preventing false matches against serial numbers and invented year ranges.
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
  });

  String? modelName;
  int? modelYear;
  String? vin;
  int? odometerKm;
  String? notes;
  bool isAutoIdentified;

  BmwMotorcycleModel? get model => BmwVehicleCatalog.findByName(modelName);

  bool get hasVehicle => modelName != null;

  Map<String, dynamic> toJson() => {
        'modelName': modelName,
        'modelYear': modelYear,
        'vin': vin,
        'odometerKm': odometerKm,
        'notes': notes,
        'isAutoIdentified': isAutoIdentified,
      };

  factory VehicleProfile.fromJson(Map<String, dynamic> json) => VehicleProfile(
        modelName: json['modelName'] as String?,
        modelYear: json['modelYear'] as int?,
        vin: json['vin'] as String?,
        odometerKm: json['odometerKm'] as int?,
        notes: json['notes'] as String?,
        isAutoIdentified: json['isAutoIdentified'] as bool? ?? false,
      );
}
