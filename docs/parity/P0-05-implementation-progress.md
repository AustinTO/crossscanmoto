# P0-05 / RE-10 service implementation progress

Status: **IN PROGRESS**. This checkpoint covers the bounded cancellation and
operation-lifecycle work only. It does not claim original service-handler
parity.

## Current runtime changes

- `lib/diagnostics/service_reset_protocol.dart` accepts optional
  `shouldAbort`. It checks before each write, immediately after the response,
  after the existing 1500 ms write settle, and before/after each readback.
  Attempted writes still receive the settle delay even when cancellation is
  requested while a request is outstanding.
- `BmwServiceResetCancelledException` retains immutable, positively
  acknowledged `writtenDids` and completed `readback`. This separates
  preflight cancellation from cancellation after partial writes.
- `lib/diagnostics/service_manager.dart` forwards cancellation and returns
  `success: false, cancelled: true` with confirmed partial DIDs. It cannot
  report verified success after cancellation.
- `lib/service_coding_page.dart` exposes a Stop action, requests cancellation
  on disposal, and checks the captured `DiagnosticSession.generation`, active
  link identity, ECU key, and operation token before/after async work. It uses
  the existing exclusive operation and target rebind path.
- `lib/diagnostic_session.dart` is unchanged. The UI uses its existing
  `runExclusive`, target rebinding, generation, active-link, and ECU-key guards.

## Evidence and implementation boundary

- The corrected `FUNCTIONS` raw mapping is 8 → `CF_ADAPTIONS`, 12 →
  `CF_SERVICE`, 11 → `CF_SERVICE_FUNCTIONS`. The existing BMS allowlist derives
  from the wrong raw category and must be replaced after exact factory-to-
  handler traces are complete.
- Source worker `params_code` confirmed `fx.I(String)` at DEX `0x1b59d8`
  dispatches exact `ecu-groups.modulegroup` strings. It has traced
  `G_MRKOMB` → `cr(23)` (address 96) → `i15`, which inherits `sl0.C` and its
  E12x UDS handler. The completed route checkpoint now maps all 11 G_MRKOMB
  response IDs to exact `cuX_KOMB*` handler keys; `G_MRSLZ`/`1020064` maps to
  `cuX_CCP`. The source-derived matrix is in
  [`P0-05-service-dispatch-evidence.md`](P0-05-service-dispatch-evidence.md).
- Source worker `historical_live` is tracing the distinct KWP `qr`/`rr`
  0x3B handlers, payloads, sequencing, and gates. Do not route those through
  the UDS E12x profile. The current route evidence identifies `D_MRKOMB` →
  `cr(6)`/address 96 and KWP response labels `MRKOMB18`, `MRKOMB46`, and
  `MRKOMBI`, but does not establish an association to the `cuX_KOMB*`
  FUNCTIONS keys.
- Oracle worker owns strict service request/readback fixtures and cancellation
  tests. It is preparing exact UDS fixtures for the 12 verified
  `CF_SERVICE` keys; cancellation tests are still pending. No runtime payload
  or allowlist changes have been added yet.
- `assets/research/service-reset-recovery.md` contains a stale raw-8 service
  mapping. Its payload notes may be reviewed, but its category-to-target gate
  must not be reused.

## Verification

- Before cancellation edits, focused service protocol, diagnostic session, and
  parity feature tests passed (20 tests).
- After cancellation edits, the existing focused service protocol,
  diagnostic-session, and parity-feature tests passed (20 tests), and Dart
  analysis passed for the four scoped runtime files. These tests do not cover
  cancellation. Oracle-owned cancellation/replay tests are still pending and
  are not claimed as passing.

## Remaining work

Resolve each enabled raw-12 ECU through the exact DEX factory and controller
constructor; recover the separate KWP profile matrix; integrate only the
source-backed UDS/KWP handlers; add independent exact payload, ACK, pre-read,
post-read, and cancellation goldens; then rerun targeted and full Flutter
verification. Unknown or unbound targets must remain fail-closed.
