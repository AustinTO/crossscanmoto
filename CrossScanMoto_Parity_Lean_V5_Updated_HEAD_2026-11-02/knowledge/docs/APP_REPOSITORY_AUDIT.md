> **ARCHIVED PRE-MERGE AUDIT.** Based on ceee4cbb4c116f807db4f8fa93873e94b1907f0c. Superseded for code status by `08_HEAD_MERGE_DELTA.md` at adf98d171d0c828e60e6d7cf6fbb4d06e87c9437. Historical source inventories still useful; do not infer current defect status here.

# CrossScanMoto repository-grounded audit (2026-11-02)

**Repository**: `https://github.com/AustinTO/crossscanmoto`, default branch `main`, inspected tree SHA `ceee4cbb4c116f807db4f8fa93873e94b1907f0c`. The archive contains an AI integration proposal, not edits to the repository. Re-run verification against your checkout HEAD before implementation. Repo documentation reports passing unit and widget tests and Android app execution, but no BMW motorcycle / ECU hardware test logs were found during this review.

## Evidence inventory (count every type correctly)

| Dataset / path | Observed size | What it means | What it does NOT mean |
|---|---:|---|---|
| `lib/diagnostics/recovered_catalog.dart` raw vehicles | 84 rows | Recovered model/platform entries, including two Husqvarna and duplicated model names | 84 unique BMWs physically tested |
| `lib/diagnostics/vehicle_catalog.dart` curated models | 26 entries | Explicit hand-curated model selector | Same as raw 84 platform records |
| `lib/diagnostics/ecu_catalog.dart` | 9 ECU group definitions | Default auto scan candidates | Full 29 recovered groups queried |
| Recovered ECU model/group inventory | 29 groups | Reference metadata | 29 ECUs in any one bike |
| `assets/data/recovered_ecu_definitions.json` | 55 ECU keys | 8,017 recovered row occurrences | All rows validated on a bike |
| `TROUBLECODES` table | 5,805 row occurrences | Potential controller-specific code IDs/text IDs | 5,805 verified unique fault remedies |
| `PARAMS` table / parameter JSON | 230 requests across 21 keys | ECU-scoped UDS 0x22 read groups | 230 decoded gauge values |
| `PARAMS_RES` / `PARAMS_TAB` | 486 / 665 rows | Potential value and enumeration decoders | Verified scales/units on identified ECU software |
| `recovered_actuators.json` | 44 actuators; 61 positions; 130 command records across 6 ECU keys | Existing code/recovered definitions | Verified and authorized hardware service routines |

## Important issues discovered

1. **VIN identification is insufficiently authoritative.** `identifyFromVin` tries `vinVdsCodes`, which are empty in the curated model entries, and then searches for series code text inside VIN; `inferModelFromAddresses` chooses a model from a pattern shared by many models. `AutoScanController` may set the guessed model's `startYear` when the actual year is missing. Treat these as weak hypotheses, never sufficient to match technical instructions.
2. **CE 04 chassis mismatch.** Curated `CE 04` has `K09`; recovered raw record maps CE 04 to `K07`, and `K09` to C 400 X. Block automatic matching until resolved from primary source.
3. **Raw live-data screen.** `lib/live_data_page.dart` reads `recovered_uds_parameters.json` and displays the returned bytes as hex text. It is not a fully decoded, field-tested telemetry pipeline, despite ambitious README claims.
4. **ECU health semantics.** In `auto_scan_controller.dart`, `isHealthy` returns true for `responding && dtcs.isEmpty`, which is not evidence that the motorcycle is healthy; a DTC request might be incomplete or unsupported.
5. **ECU-scoped DTC lookup.** `BmwDtcDatabase.lookup` accepts `ecuKey` to select recovered descriptions. AutoScan calls it without `ecuKey`, so some descriptions cannot resolve or could lose controller provenance.
6. **Mixed catalogs need one reconciler.** Nine default scanner modules, 26 curated model selectors, 29 raw ECU groups, 55 keys and 84 raw vehicles are different levels. Use explicit relations `vehicle_variant -> ECU family -> identified ECU -> definition key -> source evidence` rather than string matching.
7. **Recovered actuator commands are not physical proof.** Source notes distinguish older recovered execution semantics and unvalidated controller conditions. The AI should never access direct command transport.
8. **Numeric maintenance specs in the initial four-page PDF** were research seeds, with mixed generations and missing revision/VIN boundaries. They remain quarantined until verified at the exact vehicle level.
9. **One recovered vehicle row is suspicious:** `KR2` R 12 G/S yearbegin of 2005; treat as a source-quality exception, not a credible 2005 model-year fact.
10. **No authenticated physical motorcycle evidence** was available in the repository scan. Runtime behavior must remain IMPLEMENTED_UNTESTED until captured and reviewed on real hardware.

## Suggested issue priority

**P0 correctness:** remove 'healthy' label from zero-DTC logic; suppress weak automatic VIN/model claims; stop wrong CE 04 mapping from hitting manual lookup; require ECU key for fault descriptions; block AI access to command payloads. **P1 usefulness:** validated PARAMS_RES parsers, model-aware capability matrix, read-only freeze-frame/session history, recall and manual citations, guide-based diagnostic journeys. **P2 commercial:** maintenance timeline, verified before/after reports, optional account-backed subscriptions, offline notes, user-submitted validated observations.

## Verification boundary

All counts are **code/data snapshot observations**. The original `README.md` and `docs/agent-handoff.md` claim broad implementation and passing tests. Unit and synthetic transport tests are not physical evidence of BMW ECU functionality. Capture `bike VIN partial hash`, exact ECU identity, adapter, protocol, firmware, request class, request/response checksum, outcome, interlocks, tester, and review before increasing safety-critical support labels.
