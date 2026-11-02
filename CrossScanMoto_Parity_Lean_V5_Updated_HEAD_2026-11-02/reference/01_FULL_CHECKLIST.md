# CrossScanMoto parity-first: HEAD-corrected V5 task checklist

**Status:** Rebased task plan, NOT fresh implementation; 47 original IDs preserved plus 6 merge audit tickets (53 total). Full patch status must be verified by agents against latest HEAD.
**Repository:** https://github.com/AustinTO/crossscanmoto  
**Verified merged HEAD (snapshot):** `adf98d171d0c828e60e6d7cf6fbb4d06e87c9437`; previous baseline `ceee4cbb4c116f807db4f8fa93873e94b1907f0c`. Recheck HEAD before implementation.  
**Target:** At least original MotoScan 1.110/1.83 source-supported diagnostic functionality, with no requirement to obtain a BMW or adapter for every model. Remaining original gaps require further lawful reverse engineering.

## Binding execution rules

- **No required full ELM/STN emulator or BMW ECU simulator.** Use minimal scripted mock `AdapterTransport`/`UdsRequestLink`/`KwpRequestLink` and independent golden fixture replays. Implement only those AT/ST reply cases exercised by a particular test.
- **No physical-bike fleet testing prerequisite.** Offline software parity is distinct from confirmed hardware interoperability. Small hardware samples are optional, not universal proof.
- **Never accept self-validating tests.** Golden bytes come from pinned original-code evidence, independent extracted tables or legitimately executed reference behavior. New implementation code cannot generate its own expected golden.
- **Do not downgrade the feature target.** A missing feature should send an agent to relevant original factory handlers, DEX/JADX, native tables, older versions or disassembly, not a generic unsupported banner.
- **Model/ECU/function scope and safe writes matter.** ECU control methods require identity mapping, explicit confirmation, bounded execution and reference-derived request bytes. Assistant does not emit arbitrary ECU writes.
- **Token efficiency:** start with `00_START_HERE.md`; then `python tools/task_packet.py --id RE-09`. This full checklist is for review, NOT default model context.

## Repository observations to resolve

- Recovered metadata includes 84 vehicle rows, 55 observed ECU keys and 29 ECU groups; none of those numbers establishes tested motorcycle coverage.
- Native bundle yields 5,805 TROUBLECODES row occurrences; some cross-controller DTC numbers differ in meaning.
- Parameter data: 230 parent UDS 0x22 requests over 21 ECU keys, 486 PARAMS_RES rows whose types/scales need reconstruction.
- Actuators: 44 groups/61 positions/130 command rows, requiring ECU-specific state machines and cleanup.
- Current `protocol_setup.dart` permits one UDS response token and treats NRC 0x78 pending as unsupported; resolve from original implementation, not guessed ISO-TP.
- `auto_scan_controller.dart` looks up DTCs without ECU key and can misrepresent absence of returned codes as complete health.
- `vehicle_catalog.dart` manually declares 26 models; original native vehicle catalog contains 84 recovered records and conflicting mapping details.
- `service_coding_page.dart` has local coding drafts that display success wording despite not writing a motorcycle.

## Staging

**Stage 0:** Pin source artifacts and evidence; fix misleading/safety-critical UI; create small fixture replay seams (RE-01/02/05/07 and P0).  
**Stage 1:** Reconstruct UDS and classic transport semantics, DTCs, raw-parameter decoding and service/actuator/coding handlers.  
**Stage 2:** Complete vehicle-to-ECU mapping, scan discovery, platform transport handling, and independent parity reports.  
**Stage 3:** Integrate AI companion only from typed read-only, source-grounded diagnostic evidence and separate subscription entitlements.

## Ticket ledger

**IMPORTANT:** A ticket with `merged_verify_only` must NOT be reimplemented wholesale. Verify tests and finish any gaps only. A `partial_merge_remaining` ticket keeps only its identified remaining scope. Full ticket descriptions below preserve original intent, not claims that old code is unchanged. Current status is authoritative in `ISSUE_TRACKER.csv`.


### Priority P0

#### [ ] RE-01 | Pin and fingerprint original MotoScan 1.110 and 1.83 artifacts

- **HEAD V5 status:** `open_unverified`. **Merged evidence:** No direct PR #1 code change was found that completes this original ticket. **Next action:** Inspect current HEAD and address the original remaining acceptance criteria.

- **Track:** Original Baseline
- **Relevant repo paths:** `assets/research/apk-findings.md`, `assets/research/historical-apk-acquisition.md`, `assets/research/manifest.txt`
- **Implementation:** Acquire permitted local copies and verify version, signature and SHA-256 before any comparison. Never require committing binaries to public repository. Handle version differences rather than merging evidence.
- **Acceptance:** Evidence manifest has SHA-256/version/ABI/path and command to reproduce disassembly; missing artifact explicitly blocks only that differential test.
- **Evidence:** Code patch, original-source location, independent golden fixture(s), test command/output, machine-readable status and unresolved gaps.

#### [ ] RE-02 | Rebuild exhaustive original feature/capability matrix

- **HEAD V5 status:** `open_unverified`. **Merged evidence:** No direct PR #1 code change was found that completes this original ticket. **Next action:** Inspect current HEAD and address the original remaining acceptance criteria.

- **Track:** Coverage
- **Relevant repo paths:** `assets/research/native-schema-recovery.md`, `assets/research/recovered-native/`, `lib/diagnostics/recovered_catalog.dart`
- **Implementation:** Map native vehicle ID->series/platform->group->ECU key->protocol->FUNCTIONS flags->factory handler->DTC/PARAMS/ACTUATOR/CODING/SERVICE. Track each row/edge including 130 failed table probes.
- **Acceptance:** Reproducible matrix lists all 84 vehicle entries, 55 observed ECU keys and every table action with exact source and status; no count used as physical compatibility proof.
- **Evidence:** Code patch, original-source location, independent golden fixture(s), test command/output, machine-readable status and unresolved gaps.

#### [ ] RE-03 | Recover the complete original BMW UDS transport path

- **HEAD V5 status:** `partial_merge_remaining`. **Merged evidence:** New UDS target selection now invalidates prior config on failed setup, but single-token decode and pending handling remain unresolved. **Next action:** Retain new fail-closed setup behavior. Resume original UDS response/framing reconstruction and source-derived golden tests.

- **Track:** Protocol
- **Relevant repo paths:** `assets/research/protocol-recovery.md`, `lib/diagnostics/protocol_setup.dart`, `lib/diagnostics/uds_client.dart`
- **Implementation:** Trace original vq4.x enum-18 setup, conditional STN branches, vq4.t/q and yl4.v parsing, adapter identities, response-pending and multiline behavior. Build exact independently sourced golden requests and parser tests. Do not invent generalized CAN/ISO-TP support not seen in reference.
- **Acceptance:** Source-derived byte-level golden matches for each recovered original adapter branch, plus malformed/late/truncated cases, without implementing adapter firmware.
- **Evidence:** Code patch, original-source location, independent golden fixture(s), test command/output, machine-readable status and unresolved gaps.

#### [ ] RE-04 | Recover full KWP/KWA/KWA2/FTE/classic ABS protocol families

- **HEAD V5 status:** `partial_merge_remaining`. **Merged evidence:** KWP NRC checks now match the outstanding request service; KWA/KWA2/FTE and old ABS families not reconstructed. **Next action:** Keep KWP service matching; reconstruct remaining families and verify against 1.83 and 1.110.

- **Track:** Protocol
- **Relevant repo paths:** `assets/research/protocol-recovery.md`, `assets/research/historical-protocol-1.83.md`, `lib/diagnostics/kwp_client.dart`
- **Implementation:** Reconstruct original ordinal 13-17 BMW variants, conditional FTE INIT/WORK, initializations, timers, negative responses and legacy ABS flash/error flows, not just a generic KWP 0x81 path.
- **Acceptance:** Per-family source-derived request/response goldens and scripted transport-link tests; unsupported branches recorded; no full ECU emulator required.
- **Evidence:** Code patch, original-source location, independent golden fixture(s), test command/output, machine-readable status and unresolved gaps.

#### [ ] RE-05 | Recover complete native handler factory and table access semantics

- **HEAD V5 status:** `open_unverified`. **Merged evidence:** No direct PR #1 code change was found that completes this original ticket. **Next action:** Inspect current HEAD and address the original remaining acceptance criteria.

- **Track:** Native RE
- **Relevant repo paths:** `assets/research/native-data-findings.md`, `assets/research/native-schema-disassembly.txt`, `tool/native/`
- **Implementation:** Use DEX/JADX/objdump/Ghidra and controlled native emulation to resolve constructor vtables, table methods, class dispatch, ECU key selection and missing joins; record offsets and failures. Do not infer fields from labels.
- **Acceptance:** Every dispatch used by original supported feature mapped to handler or explicit unresolved record; automated re-extraction diff is stable.
- **Evidence:** Code patch, original-source location, independent golden fixture(s), test command/output, machine-readable status and unresolved gaps.

#### [ ] RE-06 | Build a source-derived behavior oracle; execute original app only when valuable

- **HEAD V5 status:** `open_unverified`. **Merged evidence:** No direct PR #1 code change was found that completes this original ticket. **Next action:** Inspect current HEAD and address the original remaining acceptance criteria.

- **Track:** Differential
- **Relevant repo paths:** `assets/research/apk-findings.md`, `assets/research/historical-protocol-1.83.md`, `test/`
- **Implementation:** Generate independent goldens from exact reference DEX/native control flow and checked native-table output. Record expected commands, fields, state transitions and error handling with method/offset and artifact hash. Optional: run legitimately accessible original-app workflows to resolve high-value ambiguities, using minimal hooked I/O if necessary. No purchase, anti-tamper or security bypass.
- **Acceptance:** UDS, KWP, DTC, parameter, service and actuator families have machine-readable source-backed comparison records; executed-original coverage separately tagged; no requirement to execute the original APK or emulate a whole ECU.
- **Evidence:** Code patch, original-source location, independent golden fixture(s), test command/output, machine-readable status and unresolved gaps.

#### [ ] RE-07 | Build minimal scripted transport and request-link replay fakes (no full emulator)

- **HEAD V5 status:** `partial_merge_remaining`. **Merged evidence:** New scripted target-reconfiguration, KWP, actuator and mileage tests extend the existing fake-transport seams. **Next action:** Reuse these tests; add independent source-derived golden cases, no broad virtual adapter.

- **Track:** Offline Replay
- **Relevant repo paths:** `lib/diagnostics/elm_session.dart`, `lib/diagnostics/protocol_setup.dart`, `lib/diagnostics/kwp_client.dart`, `test/`
- **Implementation:** Use existing AdapterTransport, UdsRequestLink and KwpRequestLink seams. Supply scripted command/reply queues and deterministic fake clock/delay injection where needed. Cover AT/ST responses required by a tested function, prompt/echo fragmentation, positive/negative service replies, timeouts, pending, disconnect and racing session changes. Do NOT build a general virtual ELM/STN firmware clone, ISO-TP stack or full BMW ECU network.
- **Acceptance:** Focused original-derived fixtures replay through existing Dart interfaces; unexpected requests fail loudly; independently sourced expected frames retained; all relevant error cases deterministic. No full adapter or ECU simulator deliverable.
- **Evidence:** Code patch, original-source location, independent golden fixture(s), test command/output, machine-readable status and unresolved gaps.

#### [ ] RE-08 | Reconstruct complete DTC IDs, strings, statuses and applicability

- **HEAD V5 status:** `open_unverified`. **Merged evidence:** No direct PR #1 code change was found that completes this original ticket. **Next action:** Inspect current HEAD and address the original remaining acceptance criteria.

- **Track:** DTC
- **Relevant repo paths:** `assets/data/recovered_ecu_definitions.json`, `lib/diagnostics/recovered_dtc_descriptions.dart`, `lib/diagnostics/dtc_database.dart`
- **Implementation:** Rejoin ECU-scoped `TROUBLECODES` with localized strings, BMW 24-bit status semantics, classic 16-bit format and vendor version. Audit 5,805 occurrences including ambiguous code collisions.
- **Acceptance:** Every recovered DTC row reports translation coverage and source; same code on two controllers never picks a wrong unscoped message; snapshot stores raw status.
- **Evidence:** Code patch, original-source location, independent golden fixture(s), test command/output, machine-readable status and unresolved gaps.

#### [ ] RE-09 | Recover the full PARAMS/PARAMS_RES/PARAMS_TAB decode pipeline

- **HEAD V5 status:** `open_unverified`. **Merged evidence:** No direct PR #1 code change was found that completes this original ticket. **Next action:** Inspect current HEAD and address the original remaining acceptance criteria.

- **Track:** Live Data
- **Relevant repo paths:** `assets/data/recovered_ecu_definitions.json`, `assets/data/recovered_uds_parameters.json`, `assets/research/native-schema-recovery.md`
- **Implementation:** Trace original signedness, byte offsets, byte order, multipliers/divisors, enums, units, flags, global tables and error states. 230 requests are just query parents; 486 result rows require decoding and validation.
- **Acceptance:** Cross-implementation golden values for each resolved decoder type and every ECU-keyed response layout; raw fallback only when genuinely unresolved.
- **Evidence:** Code patch, original-source location, independent golden fixture(s), test command/output, machine-readable status and unresolved gaps.

#### [ ] RE-10 | Recover all original service handlers including legacy KWP

- **HEAD V5 status:** `open_unverified`. **Merged evidence:** No direct PR #1 code change was found that completes this original ticket. **Next action:** Inspect current HEAD and address the original remaining acceptance criteria.

- **Track:** Service
- **Relevant repo paths:** `assets/research/service-reset-recovery.md`, `lib/diagnostics/service_reset_protocol.dart`, `lib/diagnostics/kwp_client.dart`
- **Implementation:** Implement source-backed factory-selected service handlers `sl0`, relevant `qr`/`rr` legacy 0x3B variants and distinct ECU gates; retain strict input validation, pre-reads, positive ACK and post-readbacks.
- **Acceptance:** Each originally enabled service action has exact request/readback golden replay via UdsRequestLink or KwpRequestLink; no unscoped fallback to E12x.
- **Evidence:** Code patch, original-source location, independent golden fixture(s), test command/output, machine-readable status and unresolved gaps.

#### [ ] RE-11 | Reconstruct complete actuator state machine per ECU

- **HEAD V5 status:** `partial_merge_remaining`. **Merged evidence:** Actuator executor now serializes operation, supports cancellation, and attempts cleanup in more failure paths. **Next action:** Preserve cancellation/cleanup, expand ECU-specific sequencing and original-derived goldens.

- **Track:** Actuators
- **Relevant repo paths:** `assets/research/actuator-execution-recovery.md`, `assets/data/recovered_actuators.json`, `lib/diagnostics/recovered_actuators.dart`
- **Implementation:** Recover and test 44 actuator groups, 61 positions and 130 command rows. Reconstruct original Start/On/Run/Off/End selection, timing and cleanup, use exact ECU/function gates and selected session. Replay scripted acknowledgments and failures; never infer real mechanical effect.
- **Acceptance:** Byte-perfect per-ECU action sequences; negative replies, timeout and Off/End cleanup verified via scripted request-link. No virtual actuator required.
- **Evidence:** Code patch, original-source location, independent golden fixture(s), test command/output, machine-readable status and unresolved gaps.

#### [ ] P0-01 | Per-ECU original capability parity and safe runtime gates

- **HEAD V5 status:** `partial_merge_remaining`. **Merged evidence:** ECU target rebinding and rejected target invalidation are implemented, but exhaustive vehicle/function gates remain incomplete. **Next action:** Preserve rebind safeguard; recover original capability matrix and add model/ECU gate tests.

- **Track:** Safety
- **Relevant repo paths:** `lib/diagnostics/recovered_actuators.dart`, `lib/diagnostics/service_reset_protocol.dart`, `assets/data/recovered_ecu_definitions.json`
- **Implementation:** Reconstruct original per-ECU function flags, factory-selected handler and exact model->platform->ECU association, then maintain distinct parity and field-test evidence. Enable only valid bounded, user-confirmed writes; do not require testing every model to claim reconstructed software behavior.
- **Acceptance:** Each enabled operation has source offsets, factory class, ECU scope, request/response fixtures, negative/precondition tests, and confirmed local gating; model-wide blanket disables are not acceptable substitutes for reconstruction.
- **Evidence:** Code patch, original-source location, independent golden fixture(s), test command/output, machine-readable status and unresolved gaps.

#### [ ] P0-02 | Prevent wrong ECU actuator activation

- **HEAD V5 status:** `merged_verify_only`. **Merged evidence:** Central configureUdsTarget and _CurrentLink ECU-key/generation checks replace the previously unsafe reuse path. **Next action:** Run newly added target-switch and cross-ECU actuator regression tests; inspect edge cases before declaring closed.

- **Track:** Safety
- **Relevant repo paths:** `lib/recovered_actuator_panel.dart`, `lib/diagnostic_session.dart`, `lib/diagnostics/ecu_friendly_names.dart`
- **Implementation:** Bind actuator execution to verified-in-session ECU identity, address, configured protocol, controller key and immutable session generation. Reconstruct original selection logic if needed; never reuse a link configured for another target.
- **Acceptance:** Automated wrong-target, stale-link and concurrent-reconfiguration tests send zero actuator frames. Positive fixtures pass correct ECU route.
- **Evidence:** Code patch, original-source location, independent golden fixture(s), test command/output, machine-readable status and unresolved gaps.

#### [ ] P0-03 | Stop misleading actuator success claims

- **HEAD V5 status:** `merged_verify_only`. **Merged evidence:** The actuator UI now reports ECU request acknowledgments, not mechanical safety, and adds cancellation/stop behavior. **Next action:** Verify the new wording, lifecycle cancellation and cleanup tests. Do not add mechanical-success claims.

- **Track:** Safety
- **Relevant repo paths:** `lib/recovered_actuator_panel.dart`, `lib/diagnostics/recovered_actuators.dart`
- **Implementation:** Report only ECU protocol acknowledgments and cleanup outcomes. Reconstruct Start/On/Run/Off/End sequencing from original implementations and preserve its safety timeouts while improving failure cleanup.
- **Acceptance:** Differential sequence fixtures and error injections pass; UI does not assert physical movement from ACK alone.
- **Evidence:** Code patch, original-source location, independent golden fixture(s), test command/output, machine-readable status and unresolved gaps.

#### [ ] P0-04 | Validate service reset inputs and interpretation

- **HEAD V5 status:** `merged_verify_only`. **Merged evidence:** Both service UI and encoder reject mileage outside 0..65535 before writes; new service_reset_protocol_test.dart. **Next action:** Re-run boundary tests and confirm model/ECU semantics; this does not prove all service resets correct.

- **Track:** Safety
- **Relevant repo paths:** `lib/diagnostics/service_reset_protocol.dart`, `lib/diagnostics/service_manager.dart`, `lib/service_coding_page.dart`
- **Implementation:** Reconstruct E12D/other variant encodings from the correct original handler; enforce semantic constraints and no silent 16-bit wrap; keep protocol fidelity with validated safer input checks.
- **Acceptance:** Known good service-reset command byte vectors match original at each supported factory branch; invalid data emits zero frames.
- **Evidence:** Code patch, original-source location, independent golden fixture(s), test command/output, machine-readable status and unresolved gaps.

#### [ ] P0-05 | Reconstruct and accurately gate service writes

- **HEAD V5 status:** `partial_merge_remaining`. **Merged evidence:** UDS target rebinding and mileage safety improved; original KWP service handlers and per-ECU scope remain incomplete. **Next action:** Reconstruct and replay omitted original service handlers; retain the stricter write/readback path.

- **Track:** Safety
- **Relevant repo paths:** `lib/service_coding_page.dart`, `lib/diagnostics/service_manager.dart`
- **Implementation:** Restore all reference-backed per-ECU service variants and FUNCTION flag gates, rather than disabling whole families due to lack of bike fleet. Use original source and independent replay tests. Enforce explicit selected ECU, user confirmation and readback checks. Unknown targets fail closed.
- **Acceptance:** Source-backed service actions reachable on matching ECU; unsupported/ambiguous writes blocked; readback success/failure tested by scripted request links.
- **Evidence:** Code patch, original-source location, independent golden fixture(s), test command/output, machine-readable status and unresolved gaps.

#### [ ] P0-06 | Fix false vehicle coding success feedback

- **HEAD V5 status:** `partial_merge_remaining`. **Merged evidence:** Coding tab now states values are local drafts, but individual success messages still say e.g. Startup animation set. **Next action:** Change success notifications to Saved local draft only; keep live coding disabled until exact ECU write is recovered.

- **Track:** Trust
- **Relevant repo paths:** `lib/service_coding_page.dart`, `lib/diagnostics/coding_manager.dart`
- **Implementation:** Coding dropdowns currently update only local _currentValues while success wording implies motorcycle changes. Reword UI as Local Coding Drafts unless a real source-backed ECU read/write path exists. Separate local backups from ECU readback snapshots.
- **Acceptance:** Changing startup animation states locally saved draft, not motorcycle reconfigured; ECU coding confirmation shown only after scoped write and readback.
- **Evidence:** Code patch, original-source location, independent golden fixture(s), test command/output, machine-readable status and unresolved gaps.

#### [ ] P0-07 | Stop reporting DTC-free ECUs as fully healthy

- **HEAD V5 status:** `open_unverified`. **Merged evidence:** No direct PR #1 code change was found that completes this original ticket. **Next action:** Inspect current HEAD and address the original remaining acceptance criteria.

- **Track:** Trust
- **Relevant repo paths:** `lib/diagnostics/auto_scan_controller.dart`, `lib/main.dart`
- **Implementation:** Represent scan result as `DTC read succeeded: no codes returned`, `failed`, `no response`, or `partial`; never infer entire vehicle health. Preserve original scan functionality.
- **Acceptance:** Offline scenarios distinguish 0 DTC, failed request, incomplete scan, nonresponding ECU, and cancel.
- **Evidence:** Code patch, original-source location, independent golden fixture(s), test command/output, machine-readable status and unresolved gaps.

#### [ ] P0-08 | Fix wrong model/year automatic identification

- **HEAD V5 status:** `open_unverified`. **Merged evidence:** No direct PR #1 code change was found that completes this original ticket. **Next action:** Inspect current HEAD and address the original remaining acceptance criteria.

- **Track:** Data
- **Relevant repo paths:** `lib/diagnostics/vehicle_catalog.dart`, `lib/diagnostics/auto_scan_controller.dart`, `lib/diagnostics/recovered_catalog.dart`
- **Implementation:** Join native 84 vehicle records, 7 series, 29 ECU groups, 49 platform/group links and ECU key tables; reconstruct actual model-selection rules. Do not substitute address-pattern guesses for deterministic identification.
- **Acceptance:** Ambiguous vehicles require choice; every native model record has traceable group/ECU candidates; no fabricated VIN year.
- **Evidence:** Code patch, original-source location, independent golden fixture(s), test command/output, machine-readable status and unresolved gaps.

#### [ ] P0-09 | Keep AI strictly read-only

- **HEAD V5 status:** `open_unverified`. **Merged evidence:** No direct PR #1 code change was found that completes this original ticket. **Next action:** Inspect current HEAD and address the original remaining acceptance criteria.

- **Track:** Security
- **Relevant repo paths:** `lib/diagnostic_session.dart`, `backend/worker/src/index.mjs`
- **Implementation:** AI may request a sanctioned snapshot from a capability-limited interface; it cannot send arbitrary UDS/KWP, clear DTCs, mutate service data, actuate, or code; app independently authorizes any future writes.
- **Acceptance:** Prompt injection asking for raw 0x2E/0x31/0x14 produces zero device commands; service endpoints require explicit human UI interaction.
- **Evidence:** Code patch, original-source location, independent golden fixture(s), test command/output, machine-readable status and unresolved gaps.

### Priority P1

#### [ ] RE-12 | Reconstruct real coding and adaptation workflow beyond drafts

- **HEAD V5 status:** `open_unverified`. **Merged evidence:** No direct PR #1 code change was found that completes this original ticket. **Next action:** Inspect current HEAD and address the original remaining acceptance criteria.

- **Track:** Coding
- **Relevant repo paths:** `assets/research/native-schema-recovery.md`, `lib/diagnostics/coding_manager.dart`, `lib/service_coding_page.dart`
- **Implementation:** Trace easycoding native definitions, factory-selected coding methods, read/backup/write/readback logic, dependencies and rollbacks. Preserve editable drafts but implement original-backed functions instead of success toasts.
- **Acceptance:** Original-backed coding items have independently sourced serialization and scripted read/write/readback tests; drafts clearly identified; other items tracked as unresolved rather than falsely written.
- **Evidence:** Code patch, original-source location, independent golden fixture(s), test command/output, machine-readable status and unresolved gaps.

#### [ ] RE-13 | Implement real original scan/address-selection logic

- **HEAD V5 status:** `open_unverified`. **Merged evidence:** No direct PR #1 code change was found that completes this original ticket. **Next action:** Inspect current HEAD and address the original remaining acceptance criteria.

- **Track:** Scan
- **Relevant repo paths:** `assets/research/recovered-native/platform-ecu-groups.json`, `lib/diagnostics/auto_scan_controller.dart`, `lib/diagnostics/recovered_catalog.dart`
- **Implementation:** Reconstruct model+protocol+ECU scan order from original platform/group mapping and diagnostic routing. Replace 9 static UDS categories as full scan. Include classic protocol paths and cached ECU identification.
- **Acceptance:** All 84 native model records show expected candidate ECU groups; replay test scans multiple module families and does not misreport nonresponsive ECUs.
- **Evidence:** Code patch, original-source location, independent golden fixture(s), test command/output, machine-readable status and unresolved gaps.

#### [ ] RE-14 | Reconstruct original adapter support and capabilities

- **HEAD V5 status:** `open_unverified`. **Merged evidence:** No direct PR #1 code change was found that completes this original ticket. **Next action:** Inspect current HEAD and address the original remaining acceptance criteria.

- **Track:** Compatibility
- **Relevant repo paths:** `assets/research/adapter-commands.json`, `assets/research/ios-compatibility.md`, `lib/diagnostics/adapter_profile.dart`
- **Implementation:** Map original adapter probing & fallback AT/ST commands, timing, USB/SPP/Wi-Fi where observable, and iOS BLE separate. Build compatibility assertions by adapter+OS+protocol.
- **Acceptance:** Synthetic adapter fingerprints cover vendor branches and error behavior; matrix states whether direct iOS path is technically possible.
- **Evidence:** Code patch, original-source location, independent golden fixture(s), test command/output, machine-readable status and unresolved gaps.

#### [ ] RE-15 | Differential protocol recovery and error handling

- **HEAD V5 status:** `partial_merge_remaining`. **Merged evidence:** KWP negative response service matching and adapter write timeout tests improved. **Next action:** Validate full UDS, KWA, KWP, FTE error/state coverage and reference-derived bounds.

- **Track:** Failure Modes
- **Relevant repo paths:** `lib/diagnostics/elm_session.dart`, `lib/diagnostics/uds_client.dart`, `lib/diagnostics/kwp_client.dart`, `test/`
- **Implementation:** Enumerate original timeout/error/retry/session invalidation behaviors; preserve or deliberately improve safety without silent functional regression. Race/fuzz against buffers and user cancellation.
- **Acceptance:** Record and replay timeout, negative responses, bad checksum/length, no prompt, multiple frames, low voltage, disconnect and retries.
- **Evidence:** Code patch, original-source location, independent golden fixture(s), test command/output, machine-readable status and unresolved gaps.

#### [ ] RE-16 | Establish full offline parity gate and coverage dashboard

- **HEAD V5 status:** `partial_merge_remaining`. **Merged evidence:** PR #1 reports expanded Flutter/backend test suites and iOS CI but no exhaustive source-derived original parity gate. **Next action:** Re-run checks at current HEAD, then build complete per-ECU parity matrix and fixture coverage.

- **Track:** Evidence
- **Relevant repo paths:** `test/`, `tool/`, `docs/`
- **Implementation:** Track original feature/path, reachable vehicle/ECU class, handler existence, byte vectors, decode results, UI exposure, negative tests, fixtures, unresolved evidence and protection level. Measure parity by feature/path rather than model count.
- **Acceptance:** CI emits machine-readable parity matrix and fails if previously verified behavior regresses, parity-critical unimplemented paths stay visible.
- **Evidence:** Code patch, original-source location, independent golden fixture(s), test command/output, machine-readable status and unresolved gaps.

#### [ ] RE-17 | Cross-check version 1.83 versus 1.110 differences

- **HEAD V5 status:** `open_unverified`. **Merged evidence:** No direct PR #1 code change was found that completes this original ticket. **Next action:** Inspect current HEAD and address the original remaining acceptance criteria.

- **Track:** Version Drift
- **Relevant repo paths:** `assets/research/historical-protocol-1.83.md`, `assets/research/apk-findings.md`, `assets/research/service-reset-recovery.md`
- **Implementation:** Tag every recovered path by reference version; where 1.83 and 1.110 differ, prefer current applicable behavior and preserve legacy-specific variants. No unsubstantiated splice of new metadata and old execution.
- **Acceptance:** Golden fixtures are version-labeled; per-version behavior divergence has documented decision.
- **Evidence:** Code patch, original-source location, independent golden fixture(s), test command/output, machine-readable status and unresolved gaps.

#### [ ] RE-18 | Use metamorphic/fuzz/property tests for broad ECU coverage

- **HEAD V5 status:** `open_unverified`. **Merged evidence:** No direct PR #1 code change was found that completes this original ticket. **Next action:** Inspect current HEAD and address the original remaining acceptance criteria.

- **Track:** Build Quality
- **Relevant repo paths:** `test/`, `tool/`
- **Implementation:** Generate legal combinations from original tables and protocol grammar, mutate length/checksum/byte order/status/session, and replay. Use table-driven tests across ECU keys even without real BMWs.
- **Acceptance:** No crash, unsafe cross-ECU write or false success across generated cases; deterministic CI seeds and reproducible failing fixtures.
- **Evidence:** Code patch, original-source location, independent golden fixture(s), test command/output, machine-readable status and unresolved gaps.

#### [ ] RE-19 | Maintain release parity claims without fleet hardware prerequisites

- **HEAD V5 status:** `open_unverified`. **Merged evidence:** No direct PR #1 code change was found that completes this original ticket. **Next action:** Inspect current HEAD and address the original remaining acceptance criteria.

- **Track:** Shipping
- **Relevant repo paths:** `docs/production-release-audit.md`, `docs/agent-handoff.md`
- **Implementation:** Distinguish reconstructed software, static golden parity, optional executed-original comparisons, scripted cross-layer replay, sampled hardware and manufacturer documentation. Preserve accurate compatibility claims; offline correctness does not establish universal physical behavior.
- **Acceptance:** Public-facing coverage never calls 84 recovered rows physically validated; supported function claims have evidence and explicit unresolved vehicle/ECU/adapter combinations.
- **Evidence:** Code patch, original-source location, independent golden fixture(s), test command/output, machine-readable status and unresolved gaps.

#### [ ] P1-01 | Use ECU-scoped DTC lookup

- **HEAD V5 status:** `open_unverified`. **Merged evidence:** No direct PR #1 code change was found that completes this original ticket. **Next action:** Inspect current HEAD and address the original remaining acceptance criteria.

- **Track:** Accuracy
- **Relevant repo paths:** `lib/diagnostics/auto_scan_controller.dart`, `lib/diagnostics/dtc_database.dart`, `lib/diagnostics/recovered_dtc_descriptions.dart`
- **Implementation:** Resolve ecuKey from identified ECU before calling lookup(...ecuKey:). Preserve numeric raw DTC, 24-bit bytes, status mask and source; ambiguous code text remains unresolved.
- **Acceptance:** A DTC reused by two ECU keys never silently gets the wrong text; fallback does not invent a remedy.
- **Evidence:** Code patch, original-source location, independent golden fixture(s), test command/output, machine-readable status and unresolved gaps.

#### [ ] P1-02 | Persist exact DTC status/scan provenance

- **HEAD V5 status:** `open_unverified`. **Merged evidence:** No direct PR #1 code change was found that completes this original ticket. **Next action:** Inspect current HEAD and address the original remaining acceptance criteria.

- **Track:** Accuracy
- **Relevant repo paths:** `lib/diagnostics/uds_client.dart`, `lib/diagnostics/auto_scan_controller.dart`, `lib/main.dart`
- **Implementation:** Propagate individual UDS 8-bit status and status availability, timestamp, ECU address/key, VIN pseudonym, adapter, protocol, firmware, errors, scan completeness.
- **Acceptance:** Pending vs confirmed vs warning request test passes; reports retain status after navigation/relaunch; failure vs empty scan distinct.
- **Evidence:** Code patch, original-source location, independent golden fixture(s), test command/output, machine-readable status and unresolved gaps.

#### [ ] P1-03 | Handle pending and multi-frame UDS responses correctly

- **HEAD V5 status:** `open_unverified`. **Merged evidence:** No direct PR #1 code change was found that completes this original ticket. **Next action:** Inspect current HEAD and address the original remaining acceptance criteria.

- **Track:** Protocol
- **Relevant repo paths:** `lib/diagnostics/protocol_setup.dart`, `lib/diagnostics/elm_session.dart`, `lib/diagnostics/uds_client.dart`
- **Implementation:** Recover precise response parsing and adapter buffering semantics from original DEX and native code. Implement and differential-test every original supported response form (single token, split/multi-frame if present, response-pending policy). Do not invent ISO-TP semantics.
- **Acceptance:** Golden command/response corpus passes for original-supported cases across adapters; malformed/timeout cases close safely, with wire logs.
- **Evidence:** Code patch, original-source location, independent golden fixture(s), test command/output, machine-readable status and unresolved gaps.

#### [ ] P1-04 | Classify transport errors accurately and preserve recovery

- **HEAD V5 status:** `partial_merge_remaining`. **Merged evidence:** ELM write timeout regression and KWP service-specific negative-response matching added. **Next action:** Extend typed transport error handling and source-derived delayed/fragmented response tests.

- **Track:** Protocol
- **Relevant repo paths:** `lib/diagnostics/auto_scan_controller.dart`, `lib/diagnostics/elm_session.dart`, `lib/diagnostics/kwp_client.dart`
- **Implementation:** Distinguish adapter unsupported, ECU no-response, NRC negative, corrupted frame, low voltage, cancellation, timeout and disconnected adapter. Restore protocol readiness after scans; add deterministic retry budgets.
- **Acceptance:** Deterministic injected replies and link faults cover all error categories, cancellation, partial scans, and UDS/KWP reinitialization without mixed frames.
- **Evidence:** Code patch, original-source location, independent golden fixture(s), test command/output, machine-readable status and unresolved gaps.

#### [ ] P1-05 | Decode valid live-data fields from recovered parameter metadata

- **HEAD V5 status:** `open_unverified`. **Merged evidence:** No direct PR #1 code change was found that completes this original ticket. **Next action:** Inspect current HEAD and address the original remaining acceptance criteria.

- **Track:** Data
- **Relevant repo paths:** `lib/live_data_page.dart`, `assets/data/recovered_ecu_definitions.json`, `assets/data/recovered_uds_parameters.json`
- **Implementation:** Recover PARAMS_RES numeric representation and scale, units, endianness and enum joins via native decoder call graph and differential oracle. Do not leave the known original-feature fields as raw hex permanently.
- **Acceptance:** All resolved fields match independently derived golden decoded values, including signed, unsigned, enum and boundary cases; unresolved fields are explicitly tracked.
- **Evidence:** Code patch, original-source location, independent golden fixture(s), test command/output, machine-readable status and unresolved gaps.

#### [ ] P1-06 | Align supported model catalogs and ECU key mapping

- **HEAD V5 status:** `open_unverified`. **Merged evidence:** No direct PR #1 code change was found that completes this original ticket. **Next action:** Inspect current HEAD and address the original remaining acceptance criteria.

- **Track:** UX
- **Relevant repo paths:** `lib/diagnostics/vehicle_catalog.dart`, `lib/diagnostics/recovered_catalog.dart`, `lib/diagnostics/recovered_ecu_keys.dart`, `lib/diagnostics/ecu_catalog.dart`
- **Implementation:** There are 26 hand-curated model selectors vs 84 recovered records, plus 55 ECU keys vs 9 generic ECU categories. Resolve exact aliases, duplicate K61 and CE 04 K07/K09 inconsistency; keep unmapped values separate.
- **Acceptance:** A machine-readable catalog validator catches collisions and empty year ranges; no app supports claim based on record count.
- **Evidence:** Code patch, original-source location, independent golden fixture(s), test command/output, machine-readable status and unresolved gaps.

#### [ ] P1-07 | Reconcile discovered ECUs with actual readable capabilities

- **HEAD V5 status:** `open_unverified`. **Merged evidence:** No direct PR #1 code change was found that completes this original ticket. **Next action:** Inspect current HEAD and address the original remaining acceptance criteria.

- **Track:** UX
- **Relevant repo paths:** `lib/diagnostics/auto_scan_controller.dart`, `lib/diagnostics/ecu_catalog.dart`
- **Implementation:** Scan currently probes nine generic UDS addresses. Build observed ECU-level coverage and offer fallback to KWP where appropriate; do not call nine-address probe a full bike scan for every generation.
- **Acceptance:** Report shows attempted/success/error/untested counts and reason; vintage KWP profiles not silently presented as modern full scan.
- **Evidence:** Code patch, original-source location, independent golden fixture(s), test command/output, machine-readable status and unresolved gaps.

#### [ ] P1-08 | Prevent post-clear misleading scan reports

- **HEAD V5 status:** `open_unverified`. **Merged evidence:** No direct PR #1 code change was found that completes this original ticket. **Next action:** Inspect current HEAD and address the original remaining acceptance criteria.

- **Track:** Safety
- **Relevant repo paths:** `lib/diagnostic_session.dart`, `lib/diagnostics/auto_scan_controller.dart`, `lib/main.dart`
- **Implementation:** Keep before-clear snapshot, show user what clearing changes, immediately mark prior scan stale, rescan with proper ECU context, do not wipe DTCs locally without successful ECU confirmation.
- **Acceptance:** Clear failure leaves old faults and warning; success records before/after; old scan never masquerades as new.
- **Evidence:** Code patch, original-source location, independent golden fixture(s), test command/output, machine-readable status and unresolved gaps.

#### [ ] P1-09 | Test real iPhone adapter transport capabilities

- **HEAD V5 status:** `open_unverified`. **Merged evidence:** No direct PR #1 code change was found that completes this original ticket. **Next action:** Inspect current HEAD and address the original remaining acceptance criteria.

- **Track:** Mobile
- **Relevant repo paths:** `ios/Runner/AppDelegate.swift`, `lib/diagnostics/ble_transport.dart`, `assets/research/ios-compatibility.md`
- **Implementation:** Implement original-supported BLE, SPP, TCP and relay paths per platform and adapter with lifecycle tests using mock transports. Real hardware spot checks are optional but distinguish generic CoreBluetooth GATT from Bluetooth Classic SPP and vendor-specific iOS requirements.
- **Acceptance:** Mocked transport lifecycle and packet-framing tests pass; device support statements distinguish original app, current code, offline replay and any sampled hardware.
- **Evidence:** Code patch, original-source location, independent golden fixture(s), test command/output, machine-readable status and unresolved gaps.

#### [ ] P1-10 | Preserve diagnostic session exclusivity

- **HEAD V5 status:** `partial_merge_remaining`. **Merged evidence:** configureUdsTarget uses shared runExclusive; actuator execution uses shared runExclusive and serialized executor. **Next action:** Audit live data/DTC/scan/connection changes for overlap and rejection/recovery semantics.

- **Track:** Mobile
- **Relevant repo paths:** `lib/diagnostic_session.dart`, `lib/adapter_page.dart`, `lib/diagnostics/auto_scan_controller.dart`, `lib/recovered_actuator_panel.dart`
- **Implementation:** Acquire runExclusive for all raw transport and adapter-reconfig operations, prevent overlapping KWP/UDS commands, block command after generation change. Check reconnection and user cancellation races.
- **Acceptance:** Concurrent scan+parameter/actuation attempts serialize or fail clearly; stale session writes zero bytes.
- **Evidence:** Code patch, original-source location, independent golden fixture(s), test command/output, machine-readable status and unresolved gaps.

#### [ ] P1-11 | Regenerate technical inventories from pinned repository

- **HEAD V5 status:** `open_unverified`. **Merged evidence:** No direct PR #1 code change was found that completes this original ticket. **Next action:** Inspect current HEAD and address the original remaining acceptance criteria.

- **Track:** Quality
- **Relevant repo paths:** `assets/data/recovered_ecu_definitions.json`, `assets/data/recovered_uds_parameters.json`, `assets/data/recovered_actuators.json`, `tool/native/`
- **Implementation:** Regenerate completeness inventories from pinned APK/native artifacts. Investigate all 130 failed native table probes and missing handlers; never declare extraction complete from the 234 nonempty results alone. Include data provenance and release-safe licensing decisions.
- **Acceptance:** Reproducible extraction manifest and coverage report show every attempted factory/table combination and reason for empty/error/unproven.
- **Evidence:** Code patch, original-source location, independent golden fixture(s), test command/output, machine-readable status and unresolved gaps.

#### [ ] P1-12 | Review rights to ship reverse-engineered assets and guides

- **HEAD V5 status:** `open_unverified`. **Merged evidence:** No direct PR #1 code change was found that completes this original ticket. **Next action:** Inspect current HEAD and address the original remaining acceptance criteria.

- **Track:** Compliance
- **Relevant repo paths:** `assets/data/`, `assets/research/`, `docs/`
- **Implementation:** Have legal review for redistribution, localization strings, third-party tables and OEM guides. Link to lawful public manuals rather than bundling copyrighted full texts without permission. Never upload APK/decompiled code to the AI knowledge service.
- **Acceptance:** Source registry records license/permission/redistributable boolean; release artifact excludes disallowed materials.
- **Evidence:** Code patch, original-source location, independent golden fixture(s), test command/output, machine-readable status and unresolved gaps.

### Priority P2

#### [ ] RE-20 | Make AI a parity-aware guide; do not substitute text for missing functions

- **HEAD V5 status:** `open_unverified`. **Merged evidence:** No direct PR #1 code change was found that completes this original ticket. **Next action:** Inspect current HEAD and address the original remaining acceptance criteria.

- **Track:** AI
- **Relevant repo paths:** `lib/diagnostic_session.dart`, `backend/worker/src/index.mjs`, `docs/`
- **Implementation:** Assistant reads full original-derived capability matrix, selects vehicle/ECU correct diagnostics, runs read-only investigations, and points users to implemented features. It never generates arbitrary ECU write bytes.
- **Acceptance:** Questions about one KWP model or one ABS ECU return actual supported source-aware actions; unknown cases are flagged and never invented.
- **Evidence:** Code patch, original-source location, independent golden fixture(s), test command/output, machine-readable status and unresolved gaps.

#### [ ] P2-01 | Integrate V3 assistant knowledge contract with actual app data

- **HEAD V5 status:** `open_unverified`. **Merged evidence:** No direct PR #1 code change was found that completes this original ticket. **Next action:** Inspect current HEAD and address the original remaining acceptance criteria.

- **Track:** AI
- **Relevant repo paths:** `lib/diagnostic_session.dart`, `backend/worker/src/index.mjs`, `CrossScanMoto_Companion_V3/data/`
- **Implementation:** Assistant feature is not present in inspected tree. Add typed read-only context payload, evidence IDs, source references, capability states; no fabricated inspection results.
- **Acceptance:** A diagnosis answer references real captured DTC/data and cited guides; disconnected state asks for observation instead of faking telemetry.
- **Evidence:** Code patch, original-source location, independent golden fixture(s), test command/output, machine-readable status and unresolved gaps.

#### [ ] P2-02 | Build Diagnose With Me and before-after investigations

- **HEAD V5 status:** `open_unverified`. **Merged evidence:** No direct PR #1 code change was found that completes this original ticket. **Next action:** Inspect current HEAD and address the original remaining acceptance criteria.

- **Track:** AI
- **Relevant repo paths:** `lib/main.dart`, `lib/diagnostic_session.dart`, `backend/worker/`
- **Implementation:** Persist vehicle profile, symptom, scan context, observation, hypothesis, safe next test, result and repair verification. Prefer deterministic questions over open-ended chat.
- **Acceptance:** An investigation resumes after app restart; before/after compares equivalent conditions; user can export/delete case.
- **Evidence:** Code patch, original-source location, independent golden fixture(s), test command/output, machine-readable status and unresolved gaps.

#### [ ] P2-03 | Source validation, citations and confidence flags

- **HEAD V5 status:** `open_unverified`. **Merged evidence:** No direct PR #1 code change was found that completes this original ticket. **Next action:** Inspect current HEAD and address the original remaining acceptance criteria.

- **Track:** AI
- **Relevant repo paths:** `CrossScanMoto_Companion_V3/data/`, `CrossScanMoto_Companion_V3/docs/`
- **Implementation:** Respect OEM/third-party/recovered/community/experimental hierarchy; only applicable chassis/year/ECU SW docs can supply service procedure and torque numbers. Per-claim citation and date.
- **Acceptance:** Unknown torque/interval answered "not verified for your bike"; ambiguous model blocks model-specific procedure.
- **Evidence:** Code patch, original-source location, independent golden fixture(s), test command/output, machine-readable status and unresolved gaps.

#### [ ] P2-04 | Keep AI subscription separate from one-time premium unlock

- **HEAD V5 status:** `partial_merge_remaining`. **Merged evidence:** One-time premium purchase handling now uses authenticated canonical accounts and server-config gates. **Next action:** Preserve these; implement AI subscription as a distinct entitlement without migrating legacy unlocks.

- **Track:** Payments
- **Relevant repo paths:** `backend/worker/`, `lib/purchases/`, `lib/upgrade_page.dart`
- **Implementation:** Existing one-time premium purchase must not be silently converted to recurring AI entitlement. Verify subscription/store notifications, cancellations, restore, offline grace and usage caps through Worker.
- **Acceptance:** Existing paid owner retains original purchased rights; canceled AI tier does not affect diagnostics unlock; no locally forged entitlement.
- **Evidence:** Code patch, original-source location, independent golden fixture(s), test command/output, machine-readable status and unresolved gaps.

#### [ ] P2-05 | Opt-in safe evidence sharing and erase/export

- **HEAD V5 status:** `partial_merge_remaining`. **Merged evidence:** Backend account deletion and revocable server sessions hardened. **Next action:** Add AI evidence opt-in/export/delete and verify retention, not just account deletion.

- **Track:** Privacy
- **Relevant repo paths:** `backend/worker/`, `lib/preferences_page.dart`, `lib/diagnostic_session.dart`
- **Implementation:** Assistant diagnostics may include VIN, module IDs, timestamps and location implications. Default local, pseudonymize VIN, minimize payload, obtain opt-in for cloud AI, cover deletion.
- **Acceptance:** Network trace contains no raw VIN without explicit consent; delete/export tests pass; local-only use remains possible.
- **Evidence:** Code patch, original-source location, independent golden fixture(s), test command/output, machine-readable status and unresolved gaps.

#### [ ] P2-06 | Offline parity certification and representative validation

- **HEAD V5 status:** `partial_merge_remaining`. **Merged evidence:** PR #1 reports 91 Flutter and 22 backend tests with GitHub unsigned Apple builds. **Next action:** Add fixture-backed original parity gate; keep actual hardware and store validation clearly separate.

- **Track:** Release
- **Relevant repo paths:** `test/`, `tool/`, `docs/production-release-audit.md`
- **Implementation:** Treat no-full-fleet-testing as a firm development constraint. Require source-backed capability mapping, replayable golden vectors, negative/error injection and targeted property testing across all original-supported branches. Original-app execution and hardware sampling are optional escalations only when useful for a material ambiguity. Do not build full BMW ECU or ELM/STN virtual stacks.
- **Acceptance:** CI gives honest PASS/FAIL/UNRESOLVED per reference-supported branch; read-only and state-changing functions tested at existing interfaces; no synthetic self-oracle or physical-fleet prerequisite.
- **Evidence:** Code patch, original-source location, independent golden fixture(s), test command/output, machine-readable status and unresolved gaps.

## Global definition of done

1. Every reference-supported action is inventoried and mapped to selected model/ECU/adapter/protocol and original source evidence (or marked unresolved with exact reason).
2. New implementation reaches actual protocol path rather than merely listing a function name; all source-backed branches have independently derived golden request/response vectors.
3. Existing Dart link/transport seams replay success, NRC errors, malformed replies, disconnects, timeouts, and service/actuator cleanup deterministically.
4. Critical safety failures and known false UI claims are corrected; user-confirmed writes occur only with source-backed ECU scope.
5. CI publishes per-branch PASS/FAIL/UNRESOLVED, does not mask unresolved records as success, and exercises the same software under test (not only mocks of the new algorithm).
6. Verified repository tests are run on current HEAD. Physical sampling is welcome but not required for software reconstruction; no universal compatibility claim may be inferred from it.


## New merge-specific regression tickets (not included in original 47)

### [ ] MH-01 | Rebaseline all agent work and CI against merged main HEAD

- **Priority:** P0
- **Files:** `docs/release-audit.md;.github/workflows/apple-build.yml;test/;backend/worker/test/`
- **Task:** Pin merge SHA, review PR #1 changed paths, rerun flutter analyze/test and Worker tests from the actual current main. Compare CI job hashes and confirm future HEAD resync. Do not reimplement fixes simply because the old ticket is open.
- **Acceptance:** Reproducible CI/local run or explicit unavailable-tool blocker; evidence uses commit SHA, exact tests, and coverage status.
- **Status:** `open_unverified`. PR #1 reports 91 Flutter and 22 backend tests; not rerun during this package audit.
- **Next:** Run full verification once at HEAD and link its output.

### [ ] MH-02 | Regress authenticated sessions and store account binding after backend migration

- **Priority:** P1
- **Files:** `backend/worker/migrations/0003_authenticated_sessions_and_store_links.sql;backend/worker/src/index.mjs;backend/worker/test/purchases.test.mjs;lib/purchases/purchase_controller.dart`
- **Task:** Review identity/session ownership, OTP expiry, revocation, account-delete authorization, cross-account receipt replay, and one-time unlock restoration using existing tests. Preserve new server hardening; do not reset customer entitlements.
- **Acceptance:** Migration smoke tests and negative auth/receipt replay scenarios pass with no real production delete.
- **Status:** `partial_merge_remaining`. PR #1 introduced signed/revocable sessions, canonical account bindings and tests.
- **Next:** Review regression suite, migration ordering and idempotency; do not replace implemented security layer.

### [ ] MH-03 | Verify updated Apple workflow and signing preconditions

- **Priority:** P1
- **Files:** `.github/workflows/apple-build.yml;docs/apple-release.md;docs/production-configuration.md;ios/Runner.xcodeproj/project.pbxproj`
- **Task:** Verify unsigned builds in Actions; validate optional manual signed/TestFlight path secret names, bundle ID/profile compatibility, iOS 15 floor, and release artifact provenance. Do not require a Mac locally or promise signed IPA without credentials.
- **Acceptance:** Unsigned GitHub workflow documented passing; signed path either proven with actual credentialed run or clearly unverified.
- **Status:** `partial_merge_remaining`. New manual signed release workflow; PR reports successful unsigned simulator/release build.
- **Next:** Check actual workflow run and customer signing settings if available.

### [ ] MH-04 | Reconcile deployed Worker configuration, billing availability and refunds

- **Priority:** P1
- **Files:** `docs/production-configuration.md;backend/worker/src/index.mjs;backend/worker/wrangler.jsonc;lib/upgrade_page.dart`
- **Task:** Verify expected environment binding presence, purchase API availability and storefront behavior when server credentials are missing. Check that push-driven revocations are not advertised until Apple Server Notifications and Google RTDN are configured.
- **Acceptance:** Backend health, negative unauthenticated access, and entitlement state behavior reproducible; missing live notifications documented.
- **Status:** `partial_merge_remaining`. Security Worker/migration reported deployed; store secret gating added; notifications not configured in release notes.
- **Next:** Inspect release runtime config and ensure notifications/revocations are properly labeled.

### [ ] MH-05 | Regression test merged Garage state, artwork and lifecycle changes

- **Priority:** P1
- **Files:** `lib/main.dart;lib/diagnostic_session.dart;lib/recovered_actuator_panel.dart;test/dashboard_widget_test.dart;test/recovered_actuators_test.dart;assets/branding/`
- **Task:** Verify profile clearing/hydration, changing selected bikes, reconnect display, actuator stop on app backgrounding, responsive logo artwork and packaged assets. Preserve layout and safety semantics.
- **Acceptance:** Targeted widget/lifecycle tests at latest HEAD plus explicit record of any platform-only visual checks.
- **Status:** `partial_merge_remaining`. PR #1 replaced hero/icon assets and changed main UI state with new widget tests.
- **Next:** Re-run new UI tests and inspect modified state transitions.

### [ ] MH-06 | Audit cross-module target identity and session serialization after PR #1

- **Priority:** P1
- **Files:** `lib/diagnostic_session.dart;lib/recovered_actuator_panel.dart;lib/service_coding_page.dart;lib/diagnostics/auto_scan_controller.dart;lib/live_data_page.dart`
- **Task:** Trace all read/write callers and ensure ECU-key/address/link consistency, cancellation, generation and exclusive command scheduling. Avoid introducing duplicate locks that deadlock. Document any remaining unsafe transition.
- **Acceptance:** Cross-target, concurrent scan/actuator/service, disconnect and timeout test cases pass through small request-link mocks.
- **Status:** `partial_merge_remaining`. Shared target configurator and actuator serial executor added in merge.
- **Next:** Review all consumers rather than rebuilding configurator.

