import '../lib/diagnostics/recovered_catalog.dart';

void main() {
  if (RecoveredMotoScanCatalog.vehicles.length != 84 ||
      RecoveredMotoScanCatalog.ecuGroups.length != 29) {
    throw StateError('Recovered table count changed');
  }
  final ids = RecoveredMotoScanCatalog.ecuGroups.map((r) => r['id']).toSet();
  for (final association in RecoveredMotoScanCatalog.platformEcuGroups) {
    if (!ids.contains(association['ecu_groupsid'])) {
      throw StateError('Unresolved group reference');
    }
  }
  for (final vehicle in RecoveredMotoScanCatalog.vehicles) {
    RecoveredMotoScanCatalog.groupsForVehicle(vehicle['id']!);
  }
  // ignore: avoid_print
  print('PASS: original vehicle/ECU counts and all platform-group references');
}
