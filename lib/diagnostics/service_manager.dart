import 'protocol_setup.dart';
import 'service_reset_protocol.dart';

/// Standard BMW Motorrad service maintenance functions.
enum ServiceFunctionType {
  setVehicleDateTime,
  setNextServiceDate,
  setNextServiceMileage,
  setAllServiceData,
}

/// A service operation executable over BMW UDS diagnostic links.
class ServiceFunctionItem {
  const ServiceFunctionItem({
    required this.type,
    required this.title,
    required this.description,
    required this.preconditions,
  });

  final ServiceFunctionType type;
  final String title;
  final String description;
  final String preconditions;

  /// Compatibility label for ECU-detail widgets.
  String get ecuAcronym => '';
}

class ServiceExecutionResult {
  const ServiceExecutionResult({
    required this.success,
    required this.message,
    this.newServiceDate,
    this.newServiceMileageKm,
  });

  final bool success;
  final String message;
  final DateTime? newServiceDate;
  final int? newServiceMileageKm;
}

/// BMW Motorrad service reset and maintenance coordinator.
abstract final class BmwServiceManager {
  /// Supported engine management and vehicle controllers for service calibration.
  static const supportedEcuKeys = BmwServiceResetCatalog.supportedUdsEcuKeys;

  /// These actions require an explicit ECU key and a configured UDS link.
  static const actions = <ServiceFunctionItem>[
    ServiceFunctionItem(
      type: ServiceFunctionType.setVehicleDateTime,
      title: 'Set bike date and time',
      description:
          'Writes the selected vehicle clock date and time (DID E12B).',
      preconditions: 'Configure the matching supported ECU in BMW UDS first.',
    ),
    ServiceFunctionItem(
      type: ServiceFunctionType.setNextServiceDate,
      title: 'Set next service date',
      description: 'Writes the next service calendar date (DID E12C).',
      preconditions: 'Configure the matching supported ECU in BMW UDS first.',
    ),
    ServiceFunctionItem(
      type: ServiceFunctionType.setNextServiceMileage,
      title: 'Set next service mileage',
      description: 'Writes the next service mileage value (DID E12D).',
      preconditions: 'Configure the matching supported ECU in BMW UDS first.',
    ),
    ServiceFunctionItem(
      type: ServiceFunctionType.setAllServiceData,
      title: 'Update all service data',
      description: 'Writes bike date/time, service date, then mileage.',
      preconditions: 'Configure the matching supported ECU in BMW UDS first.',
    ),
  ];

  /// Kept empty for older ECU-detail and quick-action surfaces that lack an
  /// explicit ECU-key selection. They must not offer an unscoped reset.
  static const items = <ServiceFunctionItem>[];

  static Future<ServiceExecutionResult> execute({
    required ServiceFunctionItem item,
    required BmwBikeUdsLink? link,
    String? ecuKey,
    DateTime? vehicleDateTime,
    DateTime? nextServiceDate,
    int? nextServiceMileage,
  }) async {
    if (link == null || !link.isConfigured) {
      return const ServiceExecutionResult(
        success: false,
        message: 'Configure a BMW UDS ECU link before a service reset.',
      );
    }
    if (ecuKey == null || !BmwServiceResetCatalog.supportsEcuKey(ecuKey)) {
      return const ServiceExecutionResult(
        success: false,
        message: 'Select one of the supported service ECU keys explicitly.',
      );
    }
    if (vehicleDateTime == null ||
        nextServiceDate == null ||
        nextServiceMileage == null) {
      return const ServiceExecutionResult(
        success: false,
        message:
            'Provide the vehicle date, next service date, and mileage value.',
      );
    }

    try {
      final protocol = BmwServiceResetProtocol(
        link: link,
        profile: BmwServiceResetProfile.udsServiceData,
        ecuKey: ecuKey,
      );
      final result = await protocol.execute(
        action: switch (item.type) {
          ServiceFunctionType.setVehicleDateTime =>
            BmwServiceResetAction.vehicleDateTime,
          ServiceFunctionType.setNextServiceDate =>
            BmwServiceResetAction.nextServiceDate,
          ServiceFunctionType.setNextServiceMileage =>
            BmwServiceResetAction.nextServiceMileage,
          ServiceFunctionType.setAllServiceData => BmwServiceResetAction.all,
        },
        vehicleDateTime: vehicleDateTime,
        nextServiceDate: nextServiceDate,
        nextServiceMileage: nextServiceMileage,
      );
      final dateBytes =
          result.readback[BmwServiceResetProtocol.nextServiceDateDid];
      final date = dateBytes != null && dateBytes.length >= 4
          ? DateTime(
              (dateBytes[2] << 8) | dateBytes[3],
              dateBytes[1],
              dateBytes[0],
            )
          : null;
      final mileageBytes =
          result.readback[BmwServiceResetProtocol.nextServiceMileageDid];
      final mileage = mileageBytes != null && mileageBytes.length == 2
          ? (mileageBytes[0] << 8) | mileageBytes[1]
          : null;
      return ServiceExecutionResult(
        success: true,
        message:
            'ECU $ecuKey acknowledged the reset and returned service-data readback.',
        newServiceDate: date,
        newServiceMileageKm: mileage,
      );
    } catch (error) {
      return ServiceExecutionResult(
        success: false,
        message: 'Service reset failed: $error',
      );
    }
  }
}
