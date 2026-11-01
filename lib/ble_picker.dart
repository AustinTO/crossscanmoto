import 'package:flutter/material.dart';
import 'diagnostics/ble_transport.dart';

Future<BleAdapterTransport?> chooseBleAdapter(BuildContext context) async {
  final devices = await BleAdapterTransport.scan();
  if (!context.mounted) return null;
  final device = await showModalBottomSheet<BlePeripheralInfo>(
    context: context, showDragHandle: true,
    builder: (context) => SafeArea(child: ListView(shrinkWrap: true, children: [
      const ListTile(title: Text('Nearby BLE devices')),
      if (devices.isEmpty) const ListTile(title: Text('No BLE devices found')),
      for (final device in devices) ListTile(title: Text(device.name), subtitle: Text(device.id), leading: const Icon(Icons.bluetooth), onTap: () => Navigator.pop(context, device)),
    ])),
  );
  if (device == null) return null;
  final transport = await BleAdapterTransport.connect(device);
  try {
    if (!context.mounted) { await transport.close(); return null; }
    final candidates = <BleGattProfile>[];
    for (final service in transport.services) {
      for (final write in service.characteristics.where((item) => item.canWrite)) {
        for (final notify in service.characteristics.where((item) => item.canNotify)) {
          candidates.add(BleGattProfile(serviceUuid: service.uuid, writeUuid: write.uuid, notifyUuid: notify.uuid));
        }
      }
    }
    final profile = await showModalBottomSheet<BleGattProfile>(
      context: context, showDragHandle: true,
      builder: (context) => SafeArea(child: ListView(shrinkWrap: true, children: [
        const ListTile(title: Text('Adapter byte-stream profile'), subtitle: Text('Select the service and characteristics documented for your adapter.')),
        if (candidates.isEmpty) const ListTile(title: Text('No write and notify pair discovered')),
        for (final profile in candidates) ListTile(title: Text('Service ${profile.serviceUuid}'), subtitle: Text('Write ${profile.writeUuid}\nReceive ${profile.notifyUuid}'), onTap: () => Navigator.pop(context, profile)),
      ])),
    );
    if (profile == null) { await transport.close(); return null; }
    await transport.configure(profile);
    return transport;
  } catch (_) { await transport.close(); rethrow; }
}
