# iOS transport and hardware compatibility boundary

Implemented: generic CoreBluetooth discovery, service/characteristic enumeration, explicitly selected write/notify profile, notification setup, chunked writes, backpressure, connection/configuration timeouts and teardown of pending calls. Swift bridge is in ios/Runner/AppDelegate.swift; Dart bridge and picker in lib/diagnostics/ble_transport.dart and lib/ble_picker.dart.

No vendor UUID defaults are assumed. This is a usable configurable BLE transport, not proof that every MotoScan-compatible adapter is accessible from iOS. iOS native compilation has not been performed on this Linux host.

Primary sources retrieved 2026-10-30:

- https://www.obdlink.com/products/obdlink-mxp/ explicitly describes LX as not iOS-compatible; MX+ lists iOS support and Bluetooth 3.0.
- https://support.obdlink.com/support/solutions/articles/43000713351 distinguishes MX+/LX Bluetooth 3.0 and CX BLE, with different OS compatibility.
- https://developer.apple.com/accessories/ says ExternalAccessory communicates with MFi accessories over Classic Bluetooth and advises consulting the accessory manufacturer about authorizing third-party apps.
- https://developer.apple.com/documentation/corebluetooth documents CoreBluetooth APIs; availability does not imply arbitrary SPP access or vendor authorization.

MX+ app protocol access/authorization is unresolved. No access-control bypass was attempted. UniCarScan profile discovery and BMW protocol behavior must be verified on actual iOS hardware. Cross-platform shared diagnostic code does not erase accessory firmware/OS restrictions.
