# Current-source facts and remaining risks, refreshed for merged HEAD

**HEAD:** `adf98d171d0c828e60e6d7cf6fbb4d06e87c9437`  
**Previous V4 baseline:** `ceee4cbb4c116f807db4f8fa93873e94b1907f0c`  
**Change:** 3 commits ahead, 67 changed paths (including image assets) per GitHub compare; merged PR #1.

## Confirmed from merged implementation and PR source

- `DiagnosticSession.configureUdsTarget` centrally initializes the link within a shared exclusive operation and invalidates stale configuration on switches; `BmwBikeUdsLink.configure` invalidates a previous ID before new target setup.
- `RecoveredActuatorExecutor` adds serialization, cancellation and cleanup; panel has explicit stop and lifecycle hook; status describes request acknowledgments rather than mechanical safety.
- KWP negative responses are checked against the request service, preventing unrelated NRCs from triggering fallback/retry.
- Service reset mileage values reject integers outside 0–65535. `test/service_reset_protocol_test.dart` now exists.
- Backend introduces authenticated sessions and canonical store account binding, migration `0003_authenticated_sessions_and_store_links.sql`, and server-configured purchase availability.
- `.github/workflows/apple-build.yml` now includes unsigned builds and optional, explicitly dispatched signed/TestFlight work with secrets.
- Main Garage UI and icons/hero assets changed. Existing screenshots and test assertions should be refreshed where appropriate.

## Still incomplete or subject to additional reconstruction

- `lib/diagnostics/auto_scan_controller.dart` still calls `BmwDtcDatabase.lookup` **without `ecuKey`**, infers model from generic address sets, and equates fault-free ECU reply with `isHealthy`.
- `lib/main.dart` still shows `HEALTHY` in the scanned-ECU badge path.
- `lib/diagnostics/vehicle_catalog.dart` still contains weak VIN model matching (`vin.contains(seriesCode)` fallback) and heuristic address-based model assignments; native recovered 84 model rows do not equate to 84 demonstrated bike configurations.
- `lib/service_coding_page.dart` adds an explicit *local coding drafts* banner but still calls `_showCodingSuccess('Startup animation set ...')` after local-only `manager.setValue`.
- `lib/diagnostics/protocol_setup.dart` still explicitly supports one BMW UDS response token and rejects NRC 0x78 pending after the prompt; full original behavior must be recovered rather than inferred.
- `lib/live_data_page.dart` still shows raw hexadecimal data, not universally reconstructed PARAMS_RES decoded engineering values.
- `clearEcuFaults` in auto scan clears the local list, which is not itself evidence of completed ECU reread.
- Full legacy KWA/KWA2/FTE ABS, ECU-scoped coding/service families and source-proven model-to-factory routing still need reverse-engineering work.
- Apple/Google store sandbox purchases, signed iOS device distribution, real adapter and motorcycle runs were not established by this source audit. None is prerequisite to performing *software parity reconstruction*, but none should be claimed as physically tested.

**Evidence:** PR #1 (https://github.com/AustinTO/crossscanmoto/pull/1), pinned changed file paths at `adf98d171d0c828e60e6d7cf6fbb4d06e87c9437`; prior repository audit in `knowledge/docs/APP_REPOSITORY_AUDIT.md` is preserved as a historical pre-merge snapshot only.
