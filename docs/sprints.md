# CrossScan Moto — Sprint History & Roadmap

Comprehensive tracking of development sprints, engineering milestones, and current active status for CrossScan Moto, developed by Puphr LLC.

---

## Sprint Overview & Velocity Matrix

| Sprint | Focus Area | Status | Deliverables | Verification |
|---|---|---|---|---|
| **Sprint 1** | Reverse Engineering & Recovery | **Completed** | APK decompilation, DEX inventory, native `.so` disassembly, recovered database JSONs | Native schema scripts & extraction logs |
| **Sprint 2** | Transport Layer & Adapter Drivers | **Completed** | ELM327 serializer, SPP, CoreBluetooth, TCP socket, vendor profiles | `check_transport.dart`, `elm_session_test.dart` |
| **Sprint 3** | Diagnostic Protocols (UDS & KWP) | **Completed** | ISO 14229 UDS client, ISO 14230 KWP2000 client, protocol initializers | `uds_client_test.dart`, `kwp_client_test.dart` |
| **Sprint 4** | ECUs, DTCs & Live Telemetry | **Completed** | 84 models, 29 ECU groups, 24-bit DTC database, multi-category telemetry registry | `parity_features_test.dart`, `check_recovered_catalog.dart` |
| **Sprint 5** | Service, Actuators & Coding | **Completed** | Annual/distance resets, brake fluid, throttle adaptation, fan/pump actuators, TFT coding | `recovered_actuators_test.dart`, `service_manager_test` |
| **Sprint 6** | UI & Workshop Dashboard | **Completed** | 5-tab automotive cockpit, radial gauges, custom silhouette, inspection sheets | `ui_render_test.dart`, `dashboard_widget_test.dart` |
| **Sprint 7** | In-App Purchases & Backend | **Completed** | Cloudflare Worker + D1, StoreKit JWS verifier, Play Billing v3, replay guards | `purchases_test.dart`, Worker test suite |
| **Sprint 8** | Verification & Test Hardening | **Completed** | Legacy KWP page layout, teardown race fix, 67/67 automated tests passing | `flutter test`, `flutter analyze` (0 issues) |
| **Sprint 9** | Production Identity, Security & Legal | **Completed** | `com.puphr.crossscanmoto` bundle IDs, Puphr LLC attribution, Privacy Policy, Terms, Account Deletion portal & API, 68/68 tests | `flutter test`, `pnpm test` (14/14) |
| **Sprint 10** | Production Staging & Hardware Testing | **Active** | Physical bike validation, store credential provisioning, release signing | Live hardware testing & App Store staging |

---

## Detailed Sprint Logs

### Sprint 1: Reverse Engineering & Asset Recovery
- Decompiled and analyzed MotoScan 1.110 and historical 1.83 APKs.
- Recovered proprietary database tables:
  - 84 BMW Motorrad models across R, S, F, K, G, and C series.
  - 29 ECU subsystem definitions with UDS and KWP addressing.
  - Thousands of BMW 24-bit DTC codes with localized descriptions.
  - Complete actuator identifiers and execution routine parameters.
- Disassembled native ARM64 libraries (`libnative-lib.so`) to trace encryption, schema queries, and command sequence ordering.

### Sprint 2: Core Transport & Adapter Communications
- Built `ElmSession` command serializer handling command queueing, echo removal, prompt (`>`) synchronization, and response timeouts.
- Implemented multi-transport support:
  - Bluetooth Classic SPP (Android RFCOMM).
  - BLE CoreBluetooth (iOS and desktop).
  - Direct TCP sockets (Wi-Fi OBD adapters).
  - Authenticated LAN adapter relay bridge for remote diagnostics.
- Traced and implemented adapter vendor profiles (OBDLink, UniCarScan, vLinker, ELM327).

### Sprint 3: Dual-Stack Diagnostic Engine
- **ISO 14229 UDS**:
  - Request links, payload framing, and positive/negative response handling.
  - ISO-TP multi-frame transport and automatic pending response (`0x78`) waiting.
  - Services: Read Data By Identifier (`0x22`), Read DTCs (`0x19`), Clear DTCs (`0x14`), Routine Control (`0x31`), InputOutputControl (`0x2F`).
- **ISO 14230 KWP2000**:
  - K-Line link supporting fast initialization (`0x81`) and 5-baud address initialization.
  - Services: Probe & Identify (`0x1A 0x80`), Read DTCs (`0x18 0x02`), Clear DTCs (`0x14 0xFFFF`), Read Parameter (`0x21`).
- Implemented `DiagnosticSession.runExclusive` concurrency lock to guarantee atomic adapter operations.

### Sprint 4: ECU Subsystems, Fault Codes & Live Telemetry
- Implemented `EcuCatalog` and `VehicleCatalog` with persistent `VehicleProfile`.
- Built `AutoScanController` to iterate candidate buses and extract part numbers, VIN, suppliers, hardware/software revisions, and trouble codes.
- Structured `DtcDatabase` mapping 24-bit BMW DTCs with symptom descriptions and workshop recommendations.
- Developed live telemetry parameter registry with real-time stream decoding, min/max tracking, and metric/imperial unit conversions.

### Sprint 5: Workshop Functions: Service, Actuators & Coding
- **Service & Adaptations**:
  - Annual inspection date reset (12 months ahead).
  - Distance-based inspection interval reset (+10,000 km or custom distance).
  - Brake fluid flush date reset.
  - Throttle valve potentiometer adaptation relearn.
  - Lambda sensor adaptation reset.
  - Exhaust flap end-stop calibration.
  - Gear position sensor relearn.
- **Bi-Directional Actuators**:
  - Fuel pump relay activation.
  - Radiator fan test (50% and 100% duty cycles).
  - Instrument cluster needle sweep and TFT segment test.
  - Exhaust flap cycle test.
  - ABS valve cycling and return pump pulsation.
- **Vehicle Coding**:
  - TFT startup animations (BMW, M Motorsport, GS Adventure, Sport Pro).
  - Clock format (12h/24h) and measurement units (°C/°F, bar/psi/kPa, l/100km / mpg).
  - LED indicator retrofit coding and Daytime Running Lights (DRL).
  - Auxiliary fog light activation.
  - Timestamped JSON snapshot backup and restore.

### Sprint 6: Modern Dark Workshop UI
- Implemented 5-tab workshop navigation:
  1. **Garage**: Vehicle profile, battery status, quick vehicle health summary.
  2. **Systems**: ECU subsystem overview, bus scan status, and deep inspection modal sheets.
  3. **Live Data**: Real-time telemetry cockpit, animated radial gauges, parameter cards.
  4. **Workshop**: Service resets, adaptations, actuator tests, vehicle coding.
  5. **Adapter**: Connection manager (Bluetooth/WiFi/Relay), live voltage, AT terminal.
- Built custom-painted motorcycle silhouette with dynamic indicator badges.
- Implemented Preferences bottom sheet and comprehensive Workshop About dialog.

### Sprint 7: In-App Purchases & Cloudflare Backend
- Created Cloudflare Worker (`backend/worker`) with D1 SQLite persistence.
- Verified Apple App Store Server API (JWS signed data) and Google Android Publisher API (v3).
- Implemented cryptographic replay protection, transaction idempotency, and anonymous `SHA-256(accountId)` binding.
- Integrated `PurchasesClient` in Flutter app with fail-closed security guarantees.

### Sprint 8: Verification & Hardening
- Resolved `LegacyKwpPage` layout viewport clipping by introducing responsive button wrapping.
- Resolved `runExclusive` teardown synchronization in widget tests.
- Reached **100% test passing (67/67 tests)** and **0 issues** in `flutter analyze`.
- Validated all 6 standalone diagnostic verification scripts in `tool/`.

### Sprint 9: Production Identity, Security & Store Legal Compliance
- Rebranded application to **CrossScan Moto** developed by **Puphr LLC**.
- Configured application identifiers to `com.puphr.crossscanmoto` across Android (`namespace`, `applicationId`, `MainActivity.kt`) and iOS (`CFBundleDisplayName`, `CFBundleName`, `project.pbxproj`).
- Added iOS Privacy Manifest (`PrivacyInfo.xcprivacy`) declaring UserDefaults and File Timestamp APIs with zero tracking.
- Added Android `BLUETOOTH_SCAN` permission with `usesPermissionFlags="neverForLocation"`.
- Hardened Cloudflare Worker backend (`backend/worker`) with HSTS, CSP, X-Frame-Options (`DENY`), X-Content-Type-Options (`nosniff`), and strict CORS preflight.
- Created public compliance HTML web endpoints: `/privacy`, `/privacy-policy`, `/terms`, `/terms-of-service`, `/delete-account`.
- Implemented GDPR/CCPA compliant Account Deletion REST API (`DELETE /v1/account/:accountId`, `POST /v1/account/delete`) and in-app deletion UI with destructive confirmation.
- Reached **68/68 Flutter tests passing** and **14/14 backend Worker tests passing**.

---

## Active & Upcoming Sprints

### Sprint 10: Production Staging & Hardware Testing (Active)
- [ ] Bench test on physical BMW motorcycle hardware (e.g. R1250GS, S1000RR) with certified adapters (UniCarScan UCSI-2100, OBDLink LX/MX+, vLinker MC+).
- [ ] Deploy Cloudflare Worker to production:
  - `wrangler d1 create crossscanmoto-payments`
  - `wrangler d1 migrations apply crossscanmoto-payments --remote`
  - Configure production secrets: `APPLE_PRIVATE_KEY`, `GOOGLE_SERVICE_ACCOUNT_PRIVATE_KEY`
- [ ] Store console product setup: `crossscanmoto_premium_unlock` (USD 24.99).
- [ ] Release signing (iOS release provisioning profile & Android release keystore `key.properties`).
