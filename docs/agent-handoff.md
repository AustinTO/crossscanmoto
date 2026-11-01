# CrossScan Moto — Autonomous Agent & Developer Handoff

**Current Workspace State**: v2.0.0-PRO  
**Application ID / Namespace**: `com.puphr.crossscanmoto`  
**Developing Company**: Puphr LLC  
**Date / Timestamp**: 2026-10-31  
**Build Health**: `flutter analyze` 0 issues • `flutter test` 69/69 passing (100%) • Cloudflare Worker 16/16 tests passing • 6/6 Standalone check tools passing

---

## 1. Project Mission & Current State

CrossScan Moto (developed by Puphr LLC) is a professional cross-platform BMW Motorrad diagnostic and workshop software suite, completely reverse-engineered and reconstructed from MotoScan 1.110 (modern UDS/CAN) and 1.83 (legacy KWP2000/K-Line).

All core protocol engines, vehicle catalogs, DTC databases, live telemetry pipelines, workshop service routines, bi-directional actuators, vehicle coding managers, in-app purchase verification backend, legal compliance endpoints (Privacy Policy, Terms of Service, Account Deletion), and workshop UI dashboards are **100% implemented, integrated, and verified**.

---

## 2. Architecture & Key File Map

```
lib/
├── main.dart
│   └── 5-tab automotive workshop UI: Garage, Systems, Live Data, Workshop, Adapter.
│       Includes custom motorcycle silhouette canvas, radial gauges, Preferences modal,
│       in-app Privacy Policy / Terms of Service viewer, and Account Deletion confirmation dialog.
├── diagnostic_session.dart
│   └── Central app-wide state notifier. Owns ElmSession lifecycle, UDS/KWP readiness,
│       VehicleProfile, AutoScanController, and exclusive concurrency lock (`runExclusive`).
├── legacy_kwp_page.dart
│   └── Dedicated K-Line ISO 14230 diagnostic screen: fast/5-baud init, DTCs, live parameters.
├── live_data_page.dart
│   └── Real-time telemetry dashboard with multi-channel streaming and unit conversions.
├── service_coding_page.dart
│   └── Service interval resets, calibrations, bi-directional actuators, and vehicle coding.
├── ecu_detail_dialog.dart
│   └── Deep ECU inspection modal sheet (part numbers, VIN, coding, DTC inspection).
├── purchases/
│   ├── purchase_backend_api.dart  # REST client for backend entitlements & account deletion
│   ├── purchase_controller.dart   # Purchases state notifier & local secure storage cache
│   └── purchase_types.dart        # Purchase & entitlement data models
└── diagnostics/
    ├── elm_session.dart           # Command serializer, prompt ('>') sync, timeout handling
    ├── uds_client.dart            # ISO 14229 UDS protocol implementation
    ├── kwp_client.dart            # ISO 14230 KWP2000 protocol implementation
    ├── protocol_setup.dart        # BMW UDS & KWP bus initializers
    ├── ecu_catalog.dart           # 29 ECU subsystem definitions & bus addresses
    ├── vehicle_catalog.dart       # 84 BMW Motorrad models & persistent profile
    ├── dtc_database.dart          # 24-bit BMW DTC definitions, masks & remedies
    ├── live_data_definitions.dart # Multi-channel live telemetry registry
    ├── service_manager.dart       # Service reset & adaptation coordinator
    ├── service_reset_protocol.dart# Low-level service reset UDS payload encoder
    ├── actuator_manager.dart      # Bi-directional actuator output tests
    ├── recovered_actuators.dart   # Recovered actuator catalog from MotoScan
    ├── coding_manager.dart        # Vehicle coding options & snapshot backup/restore
    ├── auto_scan_controller.dart  # Multi-bus automated vehicle scan controller
    ├── ble_transport.dart         # BLE CoreBluetooth transport implementation
    └── adapter_relay_io.dart      # TCP LAN relay bridge for remote diagnostics
```

### Supporting Workspaces
- `backend/worker/`: Cloudflare Worker + D1 SQLite database (`crossscanmoto-payment-backend`) for Apple App Store (JWS) and Google Play Billing (v3) purchase verification, account deletion (`DELETE /v1/account/:accountId`), and public compliance pages (`/privacy`, `/terms`, `/delete-account`) with strict security headers (HSTS, CSP, X-Frame-Options, X-Content-Type-Options).
- `tool/`: Standalone protocol and diagnostic verification scripts (`check_transport.dart`, `check_uds.dart`, `check_protocol_setup.dart`, `check_adapter_profile.dart`, `check_adapter_relay.dart`, `check_recovered_catalog.dart`).
- `assets/data/`: Extracted JSON tables (`recovered_ecu_definitions.json`, `recovered_actuators.json`, `recovered_uds_parameters.json`).
- `ios/Runner/PrivacyInfo.xcprivacy`: Apple App Store standard privacy declaration manifest.

---

## 3. Critical Invariants & Architectural Rules

1. **Adapter Exclusivity via `DiagnosticSession.runExclusive`**:
   - The ELM327 / OBDLink transport is strictly half-duplex. Never issue raw commands or start an auto-scan, DTC read, or actuator test while another operation is running.
   - Always route diagnostic routines through `session.runExclusive(() async { ... })`.

2. **Connection Lifecycle Invariant**:
   - Diagnostic pages (such as `LegacyKwpPage` or `LiveDataPage`) must **never** close or detach `ElmSession` when disposed or popped.
   - The connection lifetime is strictly owned by the Adapter tab.

3. **UDS vs KWP Protocol Readiness**:
   - Modern BMWs use UDS over CAN/D-CAN (500 kbps); older BMWs (pre-2016 or single-wire K-Line) use KWP2000.
   - Configuring KWP invalidates UDS protocol readiness on `DiagnosticSession`. Switching back to modern UDS requires re-running protocol initialization.

4. **Widget Test Synchronization in `FakeAsync`**:
   - When writing or updating widget tests that test `runExclusive`, remember that tear-down functions must guard completer completion (e.g. `if (!completer.isCompleted) completer.complete();`) to avoid hanging the test runner outside the fake async zone.

5. **In-App Purchase & Account Security**:
   - Never grant premium entitlements locally without backend confirmation. The client must submit receipts to `POST /v1/purchases/apple` or `POST /v1/purchases/google` and receive a verified entitlement response.
   - Store and handle account IDs as cryptographically secure random UUIDs stored in `FlutterSecureStorage`.
   - Support user-initiated account deletion via in-app UI (`PurchaseController.deleteAccountAndData()`) and web endpoint (`/delete-account`).

---

## 4. Verification Runbook

Run these commands to verify the workspace at any time:

```bash
# 1. Analyze Dart sources (must report 0 issues)
flutter analyze

# 2. Run complete automated test suite (must pass 69/69 tests)
flutter test

# 3. Run all standalone protocol and catalog check scripts
dart tool/check_transport.dart
dart tool/check_uds.dart
dart tool/check_protocol_setup.dart
dart tool/check_adapter_profile.dart
dart tool/check_adapter_relay.dart
dart tool/check_recovered_catalog.dart

# 4. Run payment & auth backend worker tests (must pass 16/16 tests)
cd backend/worker && pnpm test
```

---

## 5. Immediate Next Steps for Successor Agents

1. **Physical Motorcycle & Adapter Testing**:
   - Connect to a physical BMW motorcycle (e.g., R1250GS, S1000RR) with a certified adapter (UniCarScan UCSI-2100 or OBDLink LX/MX+).
   - Test live sensor data stream performance and verify service interval resets.
2. **App Store & Play Console Provisioning**:
   - Application ID / Package Name: `com.puphr.crossscanmoto`
   - Organization: Puphr LLC
   - In-App Purchase Product ID: `crossscanmoto_premium_unlock` (USD 24.99).
3. **Cloudflare Worker Deployment**:
   - Create production D1 database: `pnpm exec wrangler d1 create crossscanmoto-payments`.
   - Update database ID in `wrangler.jsonc` and run `pnpm exec wrangler d1 migrations apply crossscanmoto-payments --remote`.
   - Set production secrets via `wrangler secret put`:
     - `APPLE_PRIVATE_KEY`, `APPLE_ISSUER_ID`, `APPLE_KEY_ID`, `APPLE_APP_ID`
     - `GOOGLE_SERVICE_ACCOUNT_EMAIL`, `GOOGLE_SERVICE_ACCOUNT_PRIVATE_KEY`
     - `SESSION_SECRET` (for signing authentication JWTs from `auth.trusthentic.com`)
   - Confirm Cloudflare Workers Send Email binding (`send_email`) is mapped to `noreply@auth.trusthentic.com`.
4. **Release Signing**:
   - Configure iOS release provisioning profile with bundle ID `com.puphr.crossscanmoto` and export `.ipa`.
   - Configure Android release keystore in `android/key.properties` for `com.puphr.crossscanmoto` and build release `.aab`.
