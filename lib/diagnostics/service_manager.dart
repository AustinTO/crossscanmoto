import 'kwp_client.dart';
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
    this.cancelled = false,
    this.writtenDids = const [],
  });

  final bool success;
  final String message;
  final DateTime? newServiceDate;
  final int? newServiceMileageKm;
  final bool cancelled;
  final List<int> writtenDids;
}

/// BMW Motorrad service reset and maintenance coordinator.
abstract final class BmwServiceManager {
  /// Exact source-enabled KOMB/CCP service controllers with an `sl0.C` route.
  static const supportedEcuKeys = BmwServiceResetCatalog.supportedUdsEcuKeys;

  /// Exact source-enabled legacy KWP KOMB service controllers with a `qr.C` or `rr.C` route.
  static const supportedKwpEcuKeys = <String>{
    'cuMRKOMB',
    'cuMRKOMB18',
    'cuMRKOMB46',
    'cuMRKOMB24',
  };

  /// All supported service ECU keys across modern UDS and legacy KWP.
  static const allSupportedEcuKeys = <String>{
    ...supportedEcuKeys,
    ...supportedKwpEcuKeys,
  };

  /// These actions require an explicit ECU key and a configured UDS or KWP link.
  static const actions = <ServiceFunctionItem>[
    ServiceFunctionItem(
      type: ServiceFunctionType.setVehicleDateTime,
      title: 'Set bike date and time',
      description:
          'Writes the vehicle clock date and time (UDS DID E12B or KWP 0x3B 0x10).',
      preconditions: 'Configure the matching supported ECU in BMW UDS or KWP first.',
    ),
    ServiceFunctionItem(
      type: ServiceFunctionType.setNextServiceDate,
      title: 'Set next service date',
      description: 'Writes the next service calendar date (UDS DID E12C or KWP 0x3B 0x11).',
      preconditions: 'Configure the matching supported ECU in BMW UDS or KWP first.',
    ),
    ServiceFunctionItem(
      type: ServiceFunctionType.setNextServiceMileage,
      title: 'Set next service mileage',
      description: 'Writes the next service mileage value (UDS DID E12D or KWP 0x3B 0x12).',
      preconditions: 'Configure the matching supported ECU in BMW UDS or KWP first.',
    ),
    ServiceFunctionItem(
      type: ServiceFunctionType.setAllServiceData,
      title: 'Update all service data',
      description: 'Writes bike date/time, service date, then mileage.',
      preconditions: 'Configure the matching supported ECU in BMW UDS or KWP first.',
    ),
  ];

  /// Kept empty for older ECU-detail and quick-action surfaces that lack an
  /// explicit ECU-key selection. They must not offer an unscoped reset.
  static const items = <ServiceFunctionItem>[];

  static Future<ServiceExecutionResult> execute({
    required ServiceFunctionItem item,
    BmwBikeUdsLink? link,
    BmwBikeKwpLink? kwpLink,
    String? ecuKey,
    DateTime? vehicleDateTime,
    DateTime? nextServiceDate,
    int? nextServiceMileage,
    bool Function()? shouldAbort,
  }) async {
    final effectiveKey = ecuKey ?? supportedEcuKeys.first;

    // Check if targeting a legacy KWP instrument cluster
    if (supportedKwpEcuKeys.contains(effectiveKey)) {
      if (kwpLink == null || !kwpLink.isConfigured) {
        return const ServiceExecutionResult(
          success: false,
          message: 'Configure a BMW KWP ECU link before a legacy service reset.',
        );
      }
      return executeKwp(
        item: item,
        link: kwpLink,
        ecuKey: effectiveKey,
        vehicleDateTime: vehicleDateTime,
        nextServiceDate: nextServiceDate,
        nextServiceMileage: nextServiceMileage,
        shouldAbort: shouldAbort,
      );
    }

    if (link == null || !link.isConfigured) {
      return const ServiceExecutionResult(
        success: false,
        message: 'Configure a BMW UDS ECU link before a service reset.',
      );
    }
    if (!BmwServiceResetCatalog.supportsEcuKey(effectiveKey)) {
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
        ecuKey: effectiveKey,
        shouldAbort: shouldAbort,
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
            'ECU $effectiveKey acknowledged the reset and returned service-data readback.',
        newServiceDate: date,
        newServiceMileageKm: mileage,
      );
    } on BmwServiceResetCancelledException catch (error) {
      return ServiceExecutionResult(
        success: false,
        cancelled: true,
        writtenDids: error.writtenDids,
        message: error.toString(),
      );
    } catch (error) {
      return ServiceExecutionResult(
        success: false,
        message: 'Service reset failed: $error',
      );
    }
  }

  /// Executes service maintenance writes against legacy KWP instrument clusters
  /// (Service 0x3B WriteDataByLocalIdentifier).
  ///
  /// Transcribes MotoScan handler qr.C / rr.C Record P/Q/R templates:
  /// - 0x3B 0x10: vehicle date/time (indices 2–8: hour, min, sec, day, month, yr_hi, yr_lo)
  /// - 0x3B 0x11: next service date (indices 2–5: day, month, yr_hi, yr_lo)
  /// - 0x3B 0x12: next service mileage (indices 2–3: mileage_hi, mileage_lo)
  static Future<ServiceExecutionResult> executeKwp({
    required ServiceFunctionItem item,
    required KwpRequestLink link,
    required String ecuKey,
    DateTime? vehicleDateTime,
    DateTime? nextServiceDate,
    int? nextServiceMileage,
    bool Function()? shouldAbort,
  }) async {
    // Fail-closed source-verified ECU allowlist check inside execution engine
    if (!supportedKwpEcuKeys.contains(ecuKey)) {
      return ServiceExecutionResult(
        success: false,
        message: 'ECU $ecuKey is not a source-verified legacy KWP service reset target.',
      );
    }

    if (shouldAbort?.call() == true) {
      return const ServiceExecutionResult(
        success: false,
        cancelled: true,
        message: 'Service reset cancelled before execution.',
      );
    }

    if (nextServiceMileage != null &&
        (nextServiceMileage < 0 || nextServiceMileage > 65535)) {
      return const ServiceExecutionResult(
        success: false,
        message: 'Service mileage must be within 0..65535 km.',
      );
    }

    final client = KwpClient(link);
    final writtenOperations = <String>[];

    try {
      final now = DateTime.now();
      final effectiveCarDate = vehicleDateTime ?? now;
      final effectiveServiceDate =
          nextServiceDate ?? now.add(const Duration(days: 365));
      final effectiveMileage = nextServiceMileage ?? 10000;

      switch (item.type) {
        case ServiceFunctionType.setVehicleDateTime:
          await client.writeVehicleDateTime(effectiveCarDate);
          writtenOperations.add('Vehicle Date/Time (0x3B 0x10)');
          break;
        case ServiceFunctionType.setNextServiceDate:
          await client.writeNextServiceDate(effectiveServiceDate);
          writtenOperations.add('Service Date (0x3B 0x11)');
          break;
        case ServiceFunctionType.setNextServiceMileage:
          await client.writeNextServiceMileage(effectiveMileage);
          writtenOperations.add('Service Mileage (0x3B 0x12)');
          break;
        case ServiceFunctionType.setAllServiceData:
          await client.writeVehicleDateTime(effectiveCarDate);
          writtenOperations.add('Vehicle Date/Time (0x3B 0x10)');
          if (shouldAbort?.call() == true) {
            return ServiceExecutionResult(
              success: false,
              cancelled: true,
              message:
                  'Service operation cancelled after writing date/time to $ecuKey.',
            );
          }
          await client.writeNextServiceDate(effectiveServiceDate);
          writtenOperations.add('Service Date (0x3B 0x11)');
          if (shouldAbort?.call() == true) {
            return ServiceExecutionResult(
              success: false,
              cancelled: true,
              message:
                  'Service operation cancelled after writing service date to $ecuKey.',
            );
          }
          await client.writeNextServiceMileage(effectiveMileage);
          writtenOperations.add('Service Mileage (0x3B 0x12)');
          break;
      }

      return ServiceExecutionResult(
        success: true,
        message:
            'Legacy KWP ECU $ecuKey acknowledged Service 0x3B write (${writtenOperations.join(", ")}); verification readback is unsupported on legacy KWP cluster.',
        newServiceDate: null,
        newServiceMileageKm: null,
      );
    } catch (error) {
      return ServiceExecutionResult(
        success: false,
        message: 'Legacy KWP service reset failed on $ecuKey: $error',
      );
    }
  }
}
