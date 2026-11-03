import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle, AssetBundle;

/// Readiness category representing the verification confidence level of an operation.
enum OperationReadiness {
  catalogOnly,
  sourceExecutionTraced,
  offlineReplayVerified,
  benchVerified,
  motorcycleVerified,
  unsupported,
}

/// Represents a motorcycle chassis entry from the BMW Motorrad extended capability catalog.
class BmwExtendedBike {
  const BmwExtendedBike({
    required this.ebr,
    required this.series,
    required this.modelName,
    this.yearBegin,
    this.yearEnd,
    this.seriesGroup,
    this.protocol = 'UDS',
    this.notes,
    this.disabled = false,
    this.platformId,
  });

  final String ebr;
  final String series;
  final String modelName;
  final int? yearBegin;
  final int? yearEnd;
  final String? seriesGroup;
  final String protocol;
  final String? notes;
  final bool disabled;
  final int? platformId;

  String get sourceQualifiedId => 'source:bmw_extended:bike:$ebr';

  factory BmwExtendedBike.fromJson(Map<String, dynamic> json) => BmwExtendedBike(
        ebr: json['ebr'] as String? ?? '',
        series: json['series'] as String? ?? '',
        modelName: json['model_name'] as String? ?? '',
        yearBegin: json['year_begin'] as int?,
        yearEnd: json['year_end'] as int?,
        seriesGroup: json['series_group'] as String?,
        protocol: json['protocol'] as String? ?? 'UDS',
        notes: json['notes'] as String?,
        disabled: json['disabled'] as bool? ?? false,
        platformId: json['platform_id'] as int?,
      );
}

/// Represents a marketed motorcycle model name mapping to an EBR chassis.
class BmwExtendedMarketModel {
  const BmwExtendedMarketModel({
    required this.ebr,
    required this.name,
    required this.seriesLetter,
    required this.ordinal,
  });

  final String ebr;
  final String name;
  final String seriesLetter;
  final int ordinal;

  factory BmwExtendedMarketModel.fromJson(Map<String, dynamic> json) =>
      BmwExtendedMarketModel(
        ebr: json['ebr'] as String? ?? '',
        name: json['name'] as String? ?? '',
        seriesLetter: json['series_letter'] as String? ?? '',
        ordinal: json['ordinal'] as int? ?? 0,
      );
}

/// Factory 4-character VDS variant code (e.g., 0A01, 0G02).
class BmwExtendedVariant {
  const BmwExtendedVariant({
    required this.ebr,
    required this.variantCode,
  });

  final String ebr;
  final String variantCode;

  String get sourceQualifiedId =>
      'source:bmw_extended:variant:$ebr:$variantCode';

  factory BmwExtendedVariant.fromJson(Map<String, dynamic> json) =>
      BmwExtendedVariant(
        ebr: json['ebr'] as String? ?? '',
        variantCode: json['variant_code'] as String? ?? '',
      );
}

/// Electronic Control Unit from the BMW Motorrad extended diagnostics catalog.
class BmwExtendedEcu {
  const BmwExtendedEcu({
    required this.name,
    required this.address,
    required this.description,
    this.cafdRoot,
    this.disabled = false,
  });

  final String name;
  final int address;
  final String description;
  final String? cafdRoot;
  final bool disabled;

  String get sourceQualifiedId => 'source:bmw_extended:ecu:$name';
  String get hexAddress =>
      '0x${address.toRadixString(16).padLeft(2, '0').toUpperCase()}';

  factory BmwExtendedEcu.fromJson(Map<String, dynamic> json) => BmwExtendedEcu(
        name: json['name'] as String? ?? '',
        address: json['address'] as int? ?? 0,
        description: json['description'] as String? ?? '',
        cafdRoot: json['cafd_root'] as String?,
        disabled: json['disabled'] as bool? ?? false,
      );
}

/// Service function definition (e.g. ABS brake bleed, adaptation reset).
class BmwExtendedServiceFunction {
  const BmwExtendedServiceFunction({
    required this.id,
    required this.ecuName,
    required this.functionId,
    required this.category,
    required this.label,
    required this.description,
    this.disabled = false,
    this.sort = 0,
  });

  final int id;
  final String ecuName;
  final String functionId;
  final String category;
  final String label;
  final String description;
  final bool disabled;
  final int sort;

  OperationReadiness get readiness =>
      disabled ? OperationReadiness.unsupported : OperationReadiness.catalogOnly;

  factory BmwExtendedServiceFunction.fromJson(Map<String, dynamic> json) =>
      BmwExtendedServiceFunction(
        id: json['id'] as int? ?? 0,
        ecuName: json['ecu_name'] as String? ?? '',
        functionId: json['function_id'] as String? ?? '',
        category: json['category'] as String? ?? '',
        label: json['label'] as String? ?? '',
        description: json['description'] as String? ?? '',
        disabled: json['disabled'] as bool? ?? false,
        sort: json['sort'] as int? ?? 0,
      );
}

/// Typed service step from state machine.
class BmwExtendedServiceStep {
  const BmwExtendedServiceStep({
    required this.id,
    required this.functionPk,
    required this.stepOrder,
    required this.kind,
    this.text,
    this.requestPdu,
    this.stopPdu,
    this.positiveResponse,
    this.keepaliveMs = 0,
    this.waitMs = 0,
    this.repeat = 1,
    this.holdPdu,
  });

  final int id;
  final int functionPk;
  final int stepOrder;
  final String kind;
  final String? text;
  final String? requestPdu;
  final String? stopPdu;
  final String? positiveResponse;
  final int keepaliveMs;
  final int waitMs;
  final int repeat;
  final String? holdPdu;

  bool get hasExecutablePdu =>
      requestPdu != null &&
      requestPdu!.isNotEmpty &&
      !requestPdu!.contains('::');

  OperationReadiness get readiness {
    if (kind == 'info') return OperationReadiness.catalogOnly;
    if (hasExecutablePdu) return OperationReadiness.sourceExecutionTraced;
    return OperationReadiness.unsupported;
  }

  factory BmwExtendedServiceStep.fromJson(Map<String, dynamic> json) =>
      BmwExtendedServiceStep(
        id: json['id'] as int? ?? 0,
        functionPk: json['function_pk'] as int? ?? 0,
        stepOrder: json['step_order'] as int? ?? 0,
        kind: json['kind'] as String? ?? '',
        text: json['text'] as String?,
        requestPdu: json['request_pdu'] as String?,
        stopPdu: json['stop_pdu'] as String?,
        positiveResponse: json['positive_response'] as String?,
        keepaliveMs: json['keepalive_ms'] as int? ?? 0,
        waitMs: json['wait_ms'] as int? ?? 0,
        repeat: json['repeat'] as int? ?? 1,
        holdPdu: json['hold_pdu'] as String?,
      );
}

/// Actuator routine or IO control component.
class BmwExtendedActuator {
  const BmwExtendedActuator({
    required this.id,
    required this.ecuName,
    required this.actuatorId,
    required this.label,
    this.requestPdu,
    this.positiveResponse,
    this.waitMs = 0,
    this.name,
    this.description,
    this.disabled = false,
  });

  final int id;
  final String ecuName;
  final String actuatorId;
  final String label;
  final String? requestPdu;
  final String? positiveResponse;
  final int waitMs;
  final String? name;
  final String? description;
  final bool disabled;

  OperationReadiness get readiness => disabled
      ? OperationReadiness.unsupported
      : OperationReadiness.sourceExecutionTraced;

  factory BmwExtendedActuator.fromJson(Map<String, dynamic> json) =>
      BmwExtendedActuator(
        id: json['id'] as int? ?? 0,
        ecuName: json['ecu_name'] as String? ?? '',
        actuatorId: json['actuator_id'] as String? ?? '',
        label: json['label'] as String? ?? '',
        requestPdu: json['request_pdu'] as String?,
        positiveResponse: json['positive_response'] as String?,
        waitMs: json['wait_ms'] as int? ?? 0,
        name: json['name'] as String?,
        description: json['description'] as String?,
        disabled: json['disabled'] as bool? ?? false,
      );
}

/// ECU adaptation parameter and reset definition.
class BmwExtendedAdaptation {
  const BmwExtendedAdaptation({
    required this.id,
    required this.ecuName,
    required this.adaptationId,
    required this.kind,
    this.readDid,
    this.resetPdu,
    this.resetResponse,
    this.label,
    this.description,
    this.disabled = false,
  });

  final int id;
  final String ecuName;
  final String adaptationId;
  final String kind;
  final String? readDid;
  final String? resetPdu;
  final String? resetResponse;
  final String? label;
  final String? description;
  final bool disabled;

  OperationReadiness get readiness => disabled
      ? OperationReadiness.unsupported
      : OperationReadiness.sourceExecutionTraced;

  factory BmwExtendedAdaptation.fromJson(Map<String, dynamic> json) =>
      BmwExtendedAdaptation(
        id: json['id'] as int? ?? 0,
        ecuName: json['ecu_name'] as String? ?? '',
        adaptationId: json['adaptation_id'] as String? ?? '',
        kind: json['kind'] as String? ?? '',
        readDid: json['read_did'] as String?,
        resetPdu: json['reset_pdu'] as String?,
        resetResponse: json['reset_response'] as String?,
        label: json['label'] as String?,
        description: json['description'] as String?,
        disabled: json['disabled'] as bool? ?? false,
      );
}

// Typedef aliases for backwards compatibility
typedef BiketuneBike = BmwExtendedBike;
typedef BiketuneMarketModel = BmwExtendedMarketModel;
typedef BiketuneVariant = BmwExtendedVariant;
typedef BiketuneEcu = BmwExtendedEcu;
typedef BiketuneServiceFunction = BmwExtendedServiceFunction;
typedef BiketuneServiceStep = BmwExtendedServiceStep;
typedef BiketuneActuator = BmwExtendedActuator;
typedef BiketuneAdaptation = BmwExtendedAdaptation;

/// Complete catalog loaded from verified BMW Motorrad JSON capability assets.
class SourceQualifiedCatalog {
  SourceQualifiedCatalog({
    required this.sourceSha256,
    required this.bikes,
    required this.marketModels,
    required this.variants,
    required this.bikeEcus,
    required this.ecus,
    required this.serviceFunctions,
    required this.serviceSteps,
    required this.actuators,
    required this.adaptations,
  }) {
    for (final b in bikes) {
      _bikesByEbr[b.ebr.toUpperCase()] = b;
    }
    for (final v in variants) {
      _variantsByEbr.putIfAbsent(v.ebr.toUpperCase(), () => []).add(v);
    }
    for (final e in ecus) {
      _ecusByName[e.name] = e;
    }
    for (final be in bikeEcus) {
      _ecuNamesByEbr.putIfAbsent(be['ebr']?.toUpperCase() ?? '', () => []).add(be['ecu_name'] ?? '');
    }
    for (final sf in serviceFunctions) {
      _functionsByEcu.putIfAbsent(sf.ecuName, () => []).add(sf);
    }
    for (final ss in serviceSteps) {
      _stepsByFunctionPk.putIfAbsent(ss.functionPk, () => []).add(ss);
    }
    for (final a in actuators) {
      _actuatorsByEcu.putIfAbsent(a.ecuName, () => []).add(a);
    }
    for (final ad in adaptations) {
      _adaptationsByEcu.putIfAbsent(ad.ecuName, () => []).add(ad);
    }
  }

  final String sourceSha256;
  final List<BmwExtendedBike> bikes;
  final List<BmwExtendedMarketModel> marketModels;
  final List<BmwExtendedVariant> variants;
  final List<Map<String, String>> bikeEcus;
  final List<BmwExtendedEcu> ecus;
  final List<BmwExtendedServiceFunction> serviceFunctions;
  final List<BmwExtendedServiceStep> serviceSteps;
  final List<BmwExtendedActuator> actuators;
  final List<BmwExtendedAdaptation> adaptations;

  final Map<String, BmwExtendedBike> _bikesByEbr = {};
  final Map<String, List<BmwExtendedVariant>> _variantsByEbr = {};
  final Map<String, BmwExtendedEcu> _ecusByName = {};
  final Map<String, List<String>> _ecuNamesByEbr = {};
  final Map<String, List<BmwExtendedServiceFunction>> _functionsByEcu = {};
  final Map<int, List<BmwExtendedServiceStep>> _stepsByFunctionPk = {};
  final Map<String, List<BmwExtendedActuator>> _actuatorsByEcu = {};
  final Map<String, List<BmwExtendedAdaptation>> _adaptationsByEcu = {};

  BmwExtendedBike? getBike(String ebr) => _bikesByEbr[ebr.toUpperCase()];

  List<BmwExtendedVariant> getVariants(String ebr) =>
      _variantsByEbr[ebr.toUpperCase()] ?? const [];

  BmwExtendedEcu? getEcu(String name) => _ecusByName[name];

  List<String> getEcuNamesForBike(String ebr) =>
      _ecuNamesByEbr[ebr.toUpperCase()] ?? const [];

  List<BmwExtendedServiceFunction> getServiceFunctions(String ecuName) =>
      _functionsByEcu[ecuName] ?? const [];

  List<BmwExtendedServiceStep> getServiceSteps(int functionPk) =>
      _stepsByFunctionPk[functionPk] ?? const [];

  List<BmwExtendedActuator> getActuators(String ecuName) =>
      _actuatorsByEcu[ecuName] ?? const [];

  List<BmwExtendedAdaptation> getAdaptations(String ecuName) =>
      _adaptationsByEcu[ecuName] ?? const [];

  /// Loads the verified extended capabilities catalog asset.
  static Future<SourceQualifiedCatalog> load({AssetBundle? bundle}) async {
    final b = bundle ?? rootBundle;
    final raw = await b.loadString('assets/data/bmw_extended_catalog.json');
    final json = jsonDecode(raw) as Map<String, dynamic>;
    final manifest = json['manifest'] as Map<String, dynamic>? ?? {};

    return SourceQualifiedCatalog(
      sourceSha256: manifest['source_sha256'] as String? ?? '',
      bikes: (json['bikes'] as List<dynamic>? ?? const [])
          .map((e) => BmwExtendedBike.fromJson(e as Map<String, dynamic>))
          .toList(growable: false),
      marketModels: (json['bike_market_models'] as List<dynamic>? ?? const [])
          .map((e) => BmwExtendedMarketModel.fromJson(e as Map<String, dynamic>))
          .toList(growable: false),
      variants: (json['bike_variants'] as List<dynamic>? ?? const [])
          .map((e) => BmwExtendedVariant.fromJson(e as Map<String, dynamic>))
          .toList(growable: false),
      bikeEcus: (json['bike_ecus'] as List<dynamic>? ?? const [])
          .map((e) => {
                'ebr': (e as Map<String, dynamic>)['ebr']?.toString() ?? '',
                'ecu_name': e['ecu_name']?.toString() ?? '',
              })
          .toList(growable: false),
      ecus: (json['ecus'] as List<dynamic>? ?? const [])
          .map((e) => BmwExtendedEcu.fromJson(e as Map<String, dynamic>))
          .toList(growable: false),
      serviceFunctions: (json['service_functions'] as List<dynamic>? ?? const [])
          .map((e) => BmwExtendedServiceFunction.fromJson(e as Map<String, dynamic>))
          .toList(growable: false),
      serviceSteps: (json['service_steps'] as List<dynamic>? ?? const [])
          .map((e) => BmwExtendedServiceStep.fromJson(e as Map<String, dynamic>))
          .toList(growable: false),
      actuators: (json['actuators'] as List<dynamic>? ?? const [])
          .map((e) => BmwExtendedActuator.fromJson(e as Map<String, dynamic>))
          .toList(growable: false),
      adaptations: (json['adaptations'] as List<dynamic>? ?? const [])
          .map((e) => BmwExtendedAdaptation.fromJson(e as Map<String, dynamic>))
          .toList(growable: false),
    );
  }
}
