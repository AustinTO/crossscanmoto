# CrossScanMoto agent handoff

Updated: 2026-11-02, service source/progress files persisted. Read this first when resuming. Keep it updated at each
verified checkpoint and before stopping or losing the session.

<!-- REPOSITORY_SNAPSHOT:START -->
## Repository snapshot

Captured 2026-11-02T19:46:22+00:00.
HEAD: `babfd584cfc67f9633b7ac9b76df8ffa0bd066d8`.
Branch: `release-hardening/production-audit`.

```text
M AGENT_HANDOFF.md
 M lib/diagnostics/auto_scan_controller.dart
 M lib/diagnostics/dtc_database.dart
 M lib/diagnostics/protocol_setup.dart
 M lib/diagnostics/vehicle_catalog.dart
 M lib/ecu_detail_dialog.dart
 M lib/legacy_kwp_page.dart
 M lib/main.dart
 M lib/recovered_actuator_panel.dart
 M test/parity_features_test.dart
 M test/protocol_setup_test.dart
?? iconbackground.png
?? iconforeground.png
```

Refresh with `python tool/update_agent_handoff.py` after a checkpoint.
This is a captured state; rerun git status before changing files.
<!-- REPOSITORY_SNAPSHOT:END -->

## User objective and operating constraints

Continue until all 53 V5 parity/implementation tickets are completed wherever
lawfully recoverable. Do not stop after a useful partial implementation or
claim full parity from mocks, source inventory counts, or an earlier PR.
Use **Luna subagents** (`model: gpt-6-luna`, `fork_turns: none`) for bounded
independent work; avoid giving every agent the full ticket list or chat.
The primary agent owns integration and independent verification.

Read the user's AGENTS guidance. One bounded ticket/workstream at a time.
Preserve all merged target rebinding, exclusivity, confirmations, cancellation,
mileage bounds, account/store security and one-time entitlements. AI stays
read-only. Never invent frames, bypass licensing/security, call local coding
edits motorcycle writes, or equate no DTCs with complete health. No full adapter
or ECU emulator and no fleet requirement. Use strict scripted request links.

This App session has no confirmed OMX CLI runtime; work uses native subagents
and an active goal, not a running Ralph/tmux team. No pause was requested.

## Repository and current status

- Workspace: `/home/austin/crossmotoapp`
- Upstream: `AustinTO/crossscanmoto`
- Correct merged audit baseline: `adf98d171d0c828e60e6d7cf6fbb4d06e87c9437`
- Last verified code/data checkpoint HEAD: `34420366df74e74a1d2c106d5f38326ff31dd930`
  (handoff-only commits may follow; obtain exact current HEAD with git).
- Prior `ceee4cbb` is obsolete for code-change status.
- Local branch is `release-hardening/production-audit`. No new commits were
  pushed. Always run `git rev-parse HEAD` and `git status --short` on resume.
- The supplied `CrossScanMoto_Parity_Lean_V5_Updated_HEAD_2026-11-02/` package
  remains untracked intentionally. **Do not delete or blindly stage it.**
- Machine tracker: `docs/parity/issue-state.json`; package's
  `state/progress.jsonl`, `state/findings.jsonl`, and `state/tickets.json` also
  record checkpoints. `.omx/state/parity/progress.json` is supplemental.

### Verified local commits

1. `c3dfb05` — original PARAMS decoding, scoped metadata, strict replay helpers,
   source evidence, independent goldens. All nine formats implemented; all
   486 retained layouts covered (268 NUMBER, 218 other layouts). 804 numeric
   vectors include Java formatting; 827 nonnumeric vectors. Original native
   `unknown text` and ASCII/BITFIELD placeholders are retained explicitly.
2. `9b39e2e` — RE-01 artifact pins and verifier. Both APKs verified for hashes,
   package/version, signer, four ABIs, DEX and native members. Negative missing
   file/hash cases rejected. No APKs/binaries committed.
3. `3442036` — RE-02 reproducible capability/routing audit. 84 vehicles, seven
   series, 29 groups, 49 platform/group edges; 68 candidate keys vs 55 keys with
   returned tables. 680 candidate key/table combinations retain 234 nonempty
   tables / 8,017 rows, 130 old failures, 316 unrecorded combinations. Five
   supplemental unindexed FUNCTIONS files remain distinct. No invented routes.
4. `6a20078` — fix(service): complete P0-05 UDS service reset routes, lifecycle, fail-closed KWP boundary, and replay verification.
5. `43b8bac` — fix(diagnostics): correct scan health reporting (hasNoReportedFaults vs health guarantee), draft notices on coding screens, candidate ECU keys for ECU-scoped resolution, and integration of 84 recovered vehicle platforms.
6. `babfd58` — feat(protocol): add UDS ELM boilerplate filtering, NRC 0x78 pending drainage, and actuator ECU parity.
7. Current — fix(parity): complete diagnostic correctness, DTC variant conflict detection and ambiguous result generation, UDS DTC status byte preservation in UI/reports, strict VDS VIN identification without substring guessing or invented year ranges, fail-closed KWP cuMRBMSMP1 actuator guard, extended NRC 0x78 pending sequence drainage, and ISO-TP multi-frame & ELM indexed response reassembly.

**Latest verified full Flutter suite:** 1,039 passed (0 failures). `flutter analyze`: 0 issues found. RE-09 Python tests: 7 passed; Backend baseline: direct `node --test backend/worker/test/purchases.test.mjs` passed 25 tests. All diagnostics, DTC, service, and protocol regression suites passing.

RE-01 is complete. RE-09 decoder and RE-02 matrix components are implemented
and verified, but their overall parity status remains unresolved pending
original inventory/routing dependencies (RE-05, RE-03/04, RE-17). **Most of the
53 tickets are still open.** Do not interpret these checkpoints as full parity.

## ACTIVE: P0-05 service correctness (supports RE-10)

A material source discrepancy was discovered during RE-02:

- `kl0` enum ordinal 8 is CF_SERVICE, **but FUNCTIONS raw IDs are not ordinals**.
- Original `jl0` constructor maps raw ID **8 -> CF_ADAPTIONS**, **12 -> CF_SERVICE**,
  11 -> CF_SERVICE_FUNCTIONS, 13 -> CF_PROGRAMMINGINFO.
- Raw ID 12 is enabled on `cuX_CCP`, `cuX_KOMB03`, `cuX_KOMB17`, `cuX_KOMB18`,
  `cuX_KOMB46`, `cuX_KOMB50`, `cuX_KOMB53`, `cuX_KOMBB2`, `cuX_KOMBHI`,
  `cuX_KOMBI`, `cuX_KOMBLO`, `cuX_KOMB_A`.
- The current service reset catalog was justified using raw ID 8 and lists
  BMS engine keys. That capability justification is wrong. It does **not**
  alone prove payload/handler incompatibility: trace the real dispatch before
  changing targets or applying generic E12x writes to other controllers.
- Critical erratum is in `assets/research/service-reset-recovery.md`.
- Proven parser offsets: kl0 clinit 0x219704; jl0 constructor 0x2198b4;
  packed switch 0x219902, payload 0x2199bc. Source excerpts are committed under
  `docs/parity/fixtures/RE-02-functions-routing-excerpts.txt`.

### Uncommitted in-progress runtime edits — NOT YET a verified checkpoint

`lib/diagnostics/service_reset_protocol.dart`,
`lib/diagnostics/service_manager.dart`, `lib/service_coding_page.dart`:
optional `shouldAbort` seam; pre/post-request/readback checks; preserved 1.5s
write settle; typed cancellation with positively acknowledged partial DIDs;
Stop/disposal/session identity invalidation in UI. **Catalog correction is now authorized against the persisted 12-key UDS
source bindings; inspect git diff to see whether it has landed. No legacy
profile may reuse UDS E12x by guessing.** Existing service/session/parity regressions were rerun: 20 passed, analyzer
clean. Cancellation-specific tests and the corrected service profiles are
still pending. Inspect current status; do not revert these edits or treat the
whole service workstream as verified. `lib/diagnostic_session.dart` was
restored to HEAD after its changes proved to be formatter-only; no session
semantics changed in this cancellation seam.

### Current native subagent scopes (session-local names)

- `params_code`: primary source dispatch evidence; owns
  `docs/parity/P0-05-service-dispatch-evidence.md` + raw excerpts. Traces
  group -> controller -> exact key/constructor selector -> enabled service
  method/profile. Found `fx.I(String)` at 0x1b59d8 mapping `ecu_groups.modulegroup`
  to `Lcr`/`Lak1` subclasses of `Lll0` and addresses; mapping continues.
- `historical_live`: concrete `qr.C`, `rr.C` legacy KWP 0x3B and `sl0.C` UDS
  bodies; owns `docs/parity/P0-05-legacy-service-evidence.md` + excerpts.
  Confirmed distinct frame families, date/mileage offsets, selector variants,
  2/3s timeouts and sl0 1500ms sleeps. Confirmed bodies are now persisted in that document with raw source excerpts;
  per-key dispatch/menu reachability is still being traced.
- `params_formats`: owns runtime service protocol/manager/page/session and
  optional `test/service_dispatch_test.dart`. Cancellation seam landed;
  waiting for exact source-backed key/profile mapping before dispatch edits.
- `params_oracle`: owns `test/fixtures/service_dispatch_goldens.json`,
  `test/service_source_replay_test.dart`, optional generator. Waiting on
  source-backed per-key profiles; no invented fixture frames. Will test abort
  before I/O and held first ACK -> abort prevents later writes/readbacks.

If these agent IDs are no longer available, their source findings must be
written into the above files or recovered from the original pinned artifacts.
All four P0-05 progress/source documents have now been created. Their
checkpoint timestamps/content take precedence over the initial summaries here.
The runtime owner notes formatting churn in the scoped files; remove only
whitespace-only changes to untouched sections, preserving semantic edits.

Additional continuously updated partial handoffs:
`docs/parity/P0-05-implementation-progress.md` and
`docs/parity/P0-05-oracle-progress.md`. Source agents were explicitly instructed
to persist partial source notes immediately, not wait for completion.

### Newly persisted service source facts

- `G_MRKOMB` -> `cr(23)` at address 96 -> eleven exact response-code-selected
  `cuX_KOMB*` keys; `G_MRSLZ` -> `ak1(0)` at address 64 -> `cuX_CCP`.
  These service controllers inherit `sl0`. See the dispatch note for all
  response discriminators; do not guess based on key suffixes.
- Legacy `D_MRKOMB` -> `cr(6)` at address 96 -> distinct qr/rr/jr selectors.
  Its raw KWP 0x3B operation must not fall through to UDS E12x writes.
- `P0-05-legacy-service-evidence.md` now records exact P/Q/R templates,
  offsets, event gating/order, original timeouts and sleeps for qr/rr/sl0.
  Original bodies ignore ACK results and have no method-local readback;
  the user's requested stricter ACK/readback checks must be retained and
  grounded in the original read-service handlers (do not invent read IDs).
- Still pending: original category/menu-to-action reachability, exact legacy
  key/profile gates, and source-backed pre/readback paths. The implementer is now correcting the UDS catalog against those twelve
  proven handler bindings; oracle fixtures should be emitted at handler level
  without waiting for unresolved legacy/menu details. Do not infer legacy
  profile bindings or read IDs.

### Immediate next actions

1. Persist source agents' confirmed dispatch/body findings promptly.
2. Resolve every enabled per-ECU service variant (UDS and original legacy
   qr/rr paths). Do not disable whole families to avoid reconstruction or
   infer that every sl0 descendant permits service.
3. Add independent exact request/start/pre-read/ACK/post-read goldens;
   integrate profiles and correct capability gates. Keep explicit ECU,
   confirmation, bounds, safe rebind/exclusivity, generation and readback.
4. Run targeted service/cancellation/session tests, then full Flutter suite
   and analyzer. Record residual unknowns separately; commit only verified
   work with Lore trailers. Update this handoff and issue trackers.
5. Continue the remaining tickets, particularly RE-05 unresolved dispatch,
   RE-03/04 transport families, P0-07 false health, P0-06 coding draft claims,
   P0-08 identification and P1-01 DTC scope. Read each packet's audit_status
   and next_action; merged_verify_only means regress first, no duplicate fix.

## Source and tooling recovery

Task packets (workspace root):

```sh
python CrossScanMoto_Parity_Lean_V5_Updated_HEAD_2026-11-02/tools/task_packet.py --id P0-05
python CrossScanMoto_Parity_Lean_V5_Updated_HEAD_2026-11-02/tools/task_packet.py --id RE-10
```

Do not load all 53 tickets into a worker. Start guidance: package
`00_START_HERE.md`, `08_HEAD_MERGE_DELTA.md`; source/evidence docs under
`docs/parity/`; original hashes in `docs/parity/original-artifacts.json`.

- Flutter: `/home/austin/sdks/flutter_sdk/flutter/bin/flutter`
- Dart: `/home/austin/sdks/flutter_sdk/flutter/bin/cache/dart-sdk/bin/dart`
- SDK: `/home/austin/Android/Sdk/build-tools/36.0.0/{aapt,apksigner,dexdump}`
- Flutter/Dart require access to their external SDK cache/telemetry; use
  `require_escalated` with justification. Do not keep trying read-only cache
  workarounds. No approval-review rejection has occurred.
- JVM Java 17, aarch64 GNU compiler/objdump and qemu-aarch64 are installed.
- Pinned official JADX 1.5.6 is currently `/tmp/crossmoto-jadx/bin/jadx`;
  ZIP SHA 545ea2be9c242511bc145755cf4bda2485ade42966e096f8b4d3da2a230e8974.
  Use `JADX_CONFIG_DIR=/tmp/crossmoto-jadx-config`,
  `JADX_CACHE_DIR=/tmp/crossmoto-jadx-cache`,
  `JADX_TMP_DIR=/tmp/crossmoto-jadx-tmp`, `-j 1 -r --single-class CLASS
  --single-class-output /tmp/CLASS.java`. Cross-check warnings/raw switches.
  REA Android MCP lacks a configured JADX JAR; local CLI fallback is working.
- Current temporary DEX inputs: `/tmp/crossmoto-re09-classes.dex` and
  `/tmp/crossmoto-re09-dexdump.txt` (1.110), `/tmp/crossmoto-183-classes.dex`
  and `/tmp/crossmoto-183-dexdump.txt` (1.83). Read dump with errors=replace.
- 1.110 APK is repository-root `MotoScan+for+BMW+Motorcycles_1.110_APKPure.apk`.
  1.83 is `/tmp/crossmoto-motoscan-1.83.apk`; both remain local/ignored.
  Temporary files may disappear; verifier/manifest and RE-01 doc retain
  hashes and extraction commands. Do not commit original binaries.

### Source traps already corrected

- Public `NativeLibMotoScan.n(String,String)` calls **private native j**,
  JNI RVA 0x6f6d84. Private native n(String) at 0x6f9574 lists series and is
  unrelated. Public p(String) calls native k(String). Do not equate wrappers
  and private native functions by spelling.
- The old text probe --ids filters native literal `unknown text`; empty
  filtered output did not prove a failed lookup. --id captured all 36 missing
  IDs as exact native placeholders (10 result labels, 43 tab rows).
- JNI j probe: 21 PARAMS positive controls match; TAB_GLOBAL 55 empty/6 null/
  seven faults across 68 candidates. Null is mapped to empty by public
  wrapper; faults remain unclassified, not proof of absent functions.
- All original native executions were bounded, offline metadata queries,
  not app execution or vehicle communication; no license/security state was
  patched. Failed probes must not be used as compatibility claims.
- Numeric dispatch is nonstandard: signed char -> unsigned byte, int labels
  -> signed16, unsigned int -> unsigned16, unsigned long -> 32-bit then Java
  signed int cast. Java Formatter ties differ from Dart toStringAsFixed;
  the source-derived formatter and 804 Java oracle vectors cover this.

## Verification commands

```sh
/home/austin/sdks/flutter_sdk/flutter/bin/flutter test --no-pub --concurrency=1
/home/austin/sdks/flutter_sdk/flutter/bin/flutter analyze --no-pub
python -m unittest discover -s tool/native -p 'test_parameter*.py' -v
python -m unittest discover -s tool/native -p 'test_capability_matrix.py' -v
cd backend/worker && node test/purchases.test.mjs
```

Local replay/source pass, CI pass and hardware validation are distinct states.
No fixed token-savings percentage or unexposed token/cache counts are assumed.
