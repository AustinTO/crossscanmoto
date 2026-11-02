# Merge delta and corrected work plan | 2026-11-02

**Repository:** https://github.com/AustinTO/crossscanmoto  
**Old V4 HEAD:** `ceee4cbb4c116f807db4f8fa93873e94b1907f0c`  
**New verified main HEAD:** `adf98d171d0c828e60e6d7cf6fbb4d06e87c9437`  
**Merge:** PR #1 at 2026-11-02 16:35:38 UTC; compare reports three commits ahead, 67 changed file paths.

## Previously assigned work already partially or substantially implemented

| Prior ticket | What is now present in merged source | Revised instruction |
|---|---|---|
| P0-02 | `configureUdsTarget` uses exclusive setup and `_CurrentLink` checks generation / ECU key | Verify wrong-target and disconnect tests. Keep original ECU capability gates as separate follow-up. |
| P0-03 / RE-11 | Serial actuator executor, cancellation, stop button, lifecycle abort, safer result text | Retain; expand original per-ECU action fixture coverage. No redundant rewrite. |
| P0-04 | UI and protocol bound service mileage at 0..65535; new tests | Regression-check. Original variant service behavior remains RE-10. |
| RE-04 / RE-15 | KWP NRC matches service; new scripted KWP tests | Retain. KWA/KWA2/FTE recovery still open. |
| P0-05 / RE-03 | UDS target invalidation and safe service rebind | Retain. Original UDS framing/pending and all service families still open. |
| P0-06 | Local coding draft clarification banner | **Partial.** Messages still say e.g. "Startup animation set" after only editing local values. |
| P1-10 | Exclusive target configuration and actuator run serialization | **Partial.** Audit all other callers/concurrent reads. |
| P2-04 / P2-05 | Canonical authenticated account, OTP/session hardening, store ownership and account deletion | Retain. Future AI subscription/evidence is separate scope. |
| P2-06 | PR reports 91 Flutter and 22 backend tests plus build workflow | Verify status. No full source-derived original software parity gate yet. |

## Confirmed gaps still in current HEAD

1. `main.dart` prints `HEALTHY` for some scanned responses and `auto_scan_controller.dart` defines `isHealthy` using DTC list emptiness, not complete health.
2. `auto_scan_controller.dart` calls DTC lookup without ECU key despite having scoped DTC catalogs; error/raw status provenance is incomplete.
3. `vehicle_catalog.dart` contains insufficient model detection heuristics; never use a guessed model to authorize ECU writes.
4. `live_data_page.dart` displays raw bytes. Reconstruct PARAMS/PARAMS_RES field offsets, scales, signedness, tables and units.
5. `protocol_setup.dart` rejects UDS pending and only accepts the original-style single-token frame; examine original variants and implement confirmed behavior.
6. `service_coding_page.dart` continues local-only dropdown success language despite stronger disclaimer.
7. Original KWA/KWA2/FTE ABS, legacy service/coding, native factory mapping and complete original capability parity still need source reconstruction.

## New PR #1 integration checks

- MH-01: Verify *actual* HEAD tests/CI rather than using outdated 69 Flutter/16 Worker test counts. PR description reports **91 Flutter/22 backend tests**; this audit did not run them.
- MH-02: Regression tests for session revocation, account ownership, migration 0003 and safe purchase restoration.
- MH-03: Confirm unsigned iOS workflow; signed and TestFlight path is manual and requires app-specific configuration.
- MH-04: Verify Worker secrets/config, checkout guards, and absence of push refund notifications; docs say those are not yet configured.
- MH-05: Widget/lifecycle checks after Garage/profile, hero/icon and actuator UI changes.
- MH-06: Cross-module ECU target/operation overlap audit.

## Lean implementation order

1. Recheck HEAD, inspect new PR #1 tests and CI, record verified baseline (MH-01). Preserve merged fixes.
2. Fix remaining misleading output (P0-07, P0-06), unsafe auto-identification (P0-08), fault-scope (P1-01), and scan statuses.
3. Resume source-backed protocol/native recovery (RE-01/02/03/04/05/07/09/10/11) using tiny scripted transports.
4. Add full software parity matrix, nonredundant fixtures and AI evidence bridge. Physical bike coverage is not a software reconstruction prerequisite.

### Evidence contracts

- `merged_verify_only`: source shows the targeted code change; test against current HEAD before marking complete.
- `partial_merge_remaining`: some former defect covered; the issue remains open solely for specific unaddressed scope.
- `open_unverified`: no sufficient code evidence of completion in this merge. It may still be addressed elsewhere: inspect current HEAD before editing.

The CSV's `next_action` overrides any stale "fix this from scratch" interpretation in the original ticket. No source code was changed by this package.
