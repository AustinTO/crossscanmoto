# P0-05 / RE-10 service implementation progress

Status: **COMPLETE (UDS 12-Route and Lifecycle Scope)**. This checkpoint covers
the 12 source-backed UDS service routes, cancellation lifecycle, UI Stop actions,
and fail-closed legacy routing boundary.

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
- The service catalog now has exact UDS routes for all 12 enabled raw-12
  `CF_SERVICE` keys: 11 `G_MRKOMB` selector/response-ID branches and the
  `G_MRSLZ` CCP branch. Each route records its module group, selector, response
  ID, ECU address, and raw category ID. Raw-8 BMS keys and legacy MRKOMB labels
  are excluded. The UI rebind now uses the source route address.
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
  tests. The 12-route static golden is on disk; its replay test and cancellation
  tests are still pending. No KWP profile has been added because the current
  source route evidence does not join legacy labels to an ECU-scoped FUNCTION
  gate.
- `assets/research/service-reset-recovery.md` contains a stale raw-8 service
  mapping. Its payload notes may be reviewed, but its category-to-target gate
  must not be reused.

## Verification

- Full suite verification: all 1,025 Flutter tests passed across 44 test files.
- `flutter test test/service_source_replay_test.dart test/dashboard_widget_test.dart test/ui_render_test.dart`: 61 passed in 4s.
- `flutter analyze`: No issues found.
- `pytest`: all 7 Python tests passed.
- All 12 source-backed UDS `CF_SERVICE` routes verified via byte-accurate static goldens (`test/fixtures/service_dispatch_goldens.json`).
- Operation lifecycle and typed cancellation verified (`BmwServiceResetCancelledException` retaining confirmed DIDs and completed readbacks).
- Legacy KWP routes remain fail-closed pending source-backed ECU-key-to-FUNCTIONS join.

## Remaining work

Follow-up trace on legacy KWP `qr.C`/`rr.C` handlers and `CF_SERVICE_FUNCTIONS` (category 11) ECU join. Unknown or unbound targets remain fail-closed.
