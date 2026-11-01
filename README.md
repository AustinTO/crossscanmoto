# CrossScan Moto

**Developing Entity**: Puphr LLC  
**Application ID**: `com.puphr.crossscanmoto`  
**Version**: 2.0.0-PRO  

Cross-platform BMW Motorrad professional diagnostics and workshop dashboard suite, reconstructed from MotoScan 1.110 and 1.83 investigations. Developed by Puphr LLC with full dual-stack transport support across Bluetooth Classic SPP (Android), BLE CoreBluetooth (iOS/cross-platform), TCP socket (Wi-Fi), and remote LAN relay bridging.

---

## Current Status (v2.0.0-PRO)

- **Static Analysis**: `flutter analyze` passes with **0 issues**.
- **Automated Test Suite**: `flutter test` reports **69/69 tests passing** (100% pass rate).
- **Backend Worker Test Suite**: `backend/worker` reports **16/16 tests passing** (100% pass rate).
- **Standalone Diagnostic Tools**: All 6 diagnostic and protocol verification scripts in `tool/` pass cleanly.
- **Physical Device Validation**: Verified running live on OnePlus 6T (Android 16 / API 36) via wireless ADB (`192.168.0.74:38245`).
- **Protocol Support**: Full dual-stack support covering modern **ISO 14229 UDS** (D-CAN / CAN bus) and legacy **ISO 14230 KWP2000** (K-Line).
- **Security & Privacy Architecture**: 100% on-device vehicle communication (zero telemetric data logged or sold), Apple App Store & Google Play purchase receipt verification on Cloudflare Workers + D1, native Email OTP authentication (`auth.trusthentic.com`), and full account deletion compliance.
- **Production Staging Guide**: Comprehensive walkthrough in [docs/production-setup-and-store-provisioning.md](file:///home/austin/crossmotoapp/docs/production-setup-and-store-provisioning.md).

---

## Capabilities & Feature Set

### 1. Dual-Stack Diagnostic Protocol Engine
- **ISO 14229 UDS over CAN / D-CAN**: High-speed 500 kbps bus diagnostics using standard 11-bit and 29-bit CAN identifiers, single-frame and multi-frame transport (ISO-TP), positive response validation, and automatic pending-response (`0x78`) handling.
- **ISO 14230 KWP2000 over K-Line**: Legacy single-wire diagnostic interface supporting 9600 and 10400 baud fast initialization (`0x81`), 5-baud address initialization, ECU identification probing (`0x1A 0x80`), fault code reading (`0x18 0x02 0xFFFF`), fault code clearing with readback (`0x14 0xFFFF`), and live parameter queries (`0x21`).
- **Adapter Vendor Profile Detection**: Traced ATI/ATRV identification identifying OBDLink (MX+, LX, SX), UniCarScan (UCSI-2000, UCSI-2100), vLinker (MC+, BM+), and standard ELM327 v1.4+ adapters with tailored timing and buffer configurations.

### 2. ECU Identification & Automated Vehicle Scan
- **Full Catalog**: 84 BMW Motorrad models across R-Series (Boxers), S-Series (Superbikes), F-Series (Parallel Twins), K-Series (Tourers & Sixes), G-Series (Singles), and C-Series (Scooters).
- **Subsystem Coverage**: 29 Electronic Control Unit categories:
  - **DME / BMS-O / BMS-MP**: Engine Management & Fuel Injection
  - **ABS / DTC**: Anti-lock Braking & Dynamic Traction Control
  - **KOMBI / TFT**: Digital Instrument Cluster & TFT Displays
  - **ZFE / BDC**: Central Vehicle Electronics & Body Controller
  - **EWS / KLR**: Electronic Immobilizer & Keyless Ride
  - **RDC / TPMS**: Tire Pressure Monitor
  - **SAF / D-ESA**: Dynamic Electronic Suspension Adjustment
  - **DWA**: Anti-Theft Alarm System
  - **RAD**: Audio & Communication Unit
- **Automated Scan**: Iterates candidate buses, identifies part numbers, VIN, suppliers, hardware/software revisions, and active trouble codes with single-tap report generation.

### 3. DTC Diagnostic Fault Management
- Standard ISO 14229 UDS DTC retrieval (`0x19 0x02 0xFF`) and confirmed clear (`0x14 0xFFFFFF`).
- BMW 24-bit trouble code database recovered from MotoScan tables with ECU-scoped descriptions, severity ratings, status byte decoding (confirmed, pending, test failed), and workshop remedy suggestions.

### 4. Real-Time Telemetry & Cockpit Gauges
- Multi-channel parameter streaming: RPM, Coolant Temp, Oil Temp, Battery Voltage, Throttle Position %, Wheel Speeds (Front/Rear), Brake Pressures, Lean Angle, Odometer, Fuel Level, Tire Pressures & Temperatures.
- Radial gauges, minimum/maximum session tracking, live chart plotting, and seamless Metric / Imperial unit conversion.

### 5. Service Resets & Adaptations
- Reset annual service inspection date (12 months ahead or custom).
- Reset distance-based inspection interval (+10,000 km or custom distance).
- Reset brake fluid flush service date.
- Throttle valve potentiometer adaptation relearn.
- Lambda sensor long-term fuel trim adaptation reset.
- Exhaust flap actuator end-stop calibration.
- Gear position sensor adaptation reset.

### 6. Actuator & Component Output Tests
- Bi-directional routine execution (`0x31 0x01` / `0x2F`):
  - Fuel pump relay activation
  - Radiator fan test (50% and 100% duty cycle)
  - Instrument cluster needle sweep & TFT display segment test
  - Exhaust flap full cycle test
  - ABS valve cycling and return pump pulsation
  - Dynamic indicator, hazard, and auxiliary lighting checks

### 7. Vehicle Coding & Configuration Backups
- TFT startup animation selection: Standard BMW, M Motorsport, GS Adventure, Sport Pro.
- Clock display format (12h / 24h) and units configuration (°C/°F, bar/psi/kPa, l/100km / mpg).
- LED indicator retrofit coding and Daytime Running Lights (DRL) configuration.
- Auxiliary fog lights activation.
- Timestamped JSON coding snapshot backup & restore with pre-validation safety checks.

### 8. Hardened Cloudflare Backend & Compliance (Puphr LLC)
- **Host**: Cloudflare Workers + Cloudflare D1 encrypted database (`backend/worker`).
- **Security Headers**: HSTS, CSP, X-Frame-Options: DENY, X-Content-Type-Options: nosniff, CORS preflight.
- **Privacy Policy**: Public web page at `/privacy` and `/privacy-policy`.
- **Terms of Service**: Public web page at `/terms` and `/terms-of-service` with workshop safety rules.
- **Account & Data Deletion**: Public web portal at `/delete-account` and in-app action triggering REST deletion (`DELETE /v1/account/:accountId`).
- **In-App Purchase Verification**: Apple App Store Server API (JWS) and Google Play Billing (v3) verification with cryptographic replay protection.

---

## Verification & Checks

```bash
# 1. Run Flutter static analysis (0 warnings / 0 errors)
flutter analyze

# 2. Run full Flutter test suite (69/69 tests passing)
flutter test

# 3. Run standalone diagnostic check scripts
dart tool/check_transport.dart
dart tool/check_uds.dart
dart tool/check_protocol_setup.dart
dart tool/check_adapter_profile.dart
dart tool/check_adapter_relay.dart
dart tool/check_recovered_catalog.dart

# 4. Run backend worker test suite (16/16 tests passing)
cd backend/worker && pnpm test
```
