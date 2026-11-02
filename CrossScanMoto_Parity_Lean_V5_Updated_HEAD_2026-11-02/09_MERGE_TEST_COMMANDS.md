# Merged HEAD regression verification commands

Run from the **current checkout** after verifying `git rev-parse HEAD`, not from the ZIP:

```bash
flutter pub get
flutter analyze
flutter test
flutter test test/diagnostic_session_test.dart test/protocol_setup_test.dart test/service_reset_protocol_test.dart test/recovered_actuators_test.dart test/kwp_client_test.dart
cd backend/worker
pnpm install --frozen-lockfile
pnpm test
```

Inspect `.github/workflows/apple-build.yml` and the actual job attached to merged PR #1 before reporting iOS build status. Do not imply a successful signed IPA or live TestFlight upload from an unsigned CI build. Migration 0003 should be smoke-tested in isolated D1 before production. Do not trigger production account deletion to prove it works.

The merged PR description reports 91 Flutter tests and 22 Worker tests; **those are externally reported counts, not runs performed here**. Run commands on matching HEAD and record exact current counts; new changes can alter counts.

Check source-derived golden fixture provenance separately: newly added unit tests may use synthetic response frames and do not alone establish compatibility across BMW ECUs.
