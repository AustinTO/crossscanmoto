# Build & Parity Validation

**Application Name**: CrossScan Moto  
**Developing Entity**: Puphr LLC  
**Application ID**: `com.puphr.crossscanmoto`  
**Version**: `2.0.0+1` (Milestone v2.0.0-PRO)  
**Date**: 2026-10-31  

## Validation Results

- **Application ID / Namespace**: `com.puphr.crossscanmoto` (Android, iOS, macOS, Linux, Windows)
- **Minimum Android SDK**: 24 (Android 7.0 Nougat)
- **Target Android SDK**: 36
- **Architecture**: ARM64-v8a, x86_64
- **iOS Privacy Manifest**: `ios/Runner/PrivacyInfo.xcprivacy` with standard API category declarations and zero tracking
- **Flutter Test Suite**: **68 / 68 PASS** (100% pass rate across 15 test files)
- **Static Analysis**: `flutter analyze` reports **0 issues found**
- **Cloudflare Worker Backend**: **14 / 14 PASS** (`node --test`) covering Apple JWS, Google v3, D1 idempotency, Account Deletion, Privacy Policy, Terms, and hardened security headers
- **Standalone Diagnostic Tools**: All 6 verification scripts in `tool/` pass:
  - `check_transport.dart`
  - `check_uds.dart`
  - `check_protocol_setup.dart`
  - `check_adapter_profile.dart`
  - `check_adapter_relay.dart`
  - `check_recovered_catalog.dart`
- **Legal & Store Compliance**:
  - In-app and web-accessible Privacy Policy (`/privacy`, `/privacy-policy`)
  - Terms of Service & Workshop Safety Disclaimers (`/terms`, `/terms-of-service`)
  - In-app Account Deletion dialog & web portal (`/delete-account`, `DELETE /v1/account/:accountId`)
  - Explicit developing entity attribution to **Puphr LLC** across all UI modals, titles, and web endpoints.
