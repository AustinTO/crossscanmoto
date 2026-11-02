# Paste to coordinating agent | CrossScanMoto V5

Repository `https://github.com/AustinTO/crossscanmoto`. Package audit captured merged main `adf98d171d0c828e60e6d7cf6fbb4d06e87c9437` (PR #1); prior baseline `ceee4cbb4c116f807db4f8fa93873e94b1907f0c` is obsolete for code-change status. Before any work, run `git rev-parse HEAD`; refresh task statuses if newer. Read `00_START_HERE.md` and `08_HEAD_MERGE_DELTA.md` only, plus `reference/ISSUE_TRACKER.csv` for task selection. Do NOT spend tokens loading all 53 tickets into every worker.

**Goal:** Original MotoScan 1.110/1.83 feature/transport parity wherever lawfully recoverable. Reverse engineer missing DEX/native handler, ECU selection, legacy protocols, DTC names, PARAMS scaling, service, coding and actuator behavior rather than defaulting to unsupported features. Preserve safe ECU target rebinding, user confirmations, cancellation and all security work already merged.

**Task selection:** `python tools/task_packet.py --list` then `python tools/task_packet.py --id RE-09` (or assigned ticket). Read the current ticket's `audit_status` and `next_action`. If `merged_verify_only`, verify regressions and avoid new implementation unless a gap is demonstrated; if `partial_merge_remaining`, implement only remaining scope. Work one bounded ticket at a time and reuse `state/findings.jsonl` + golden fixtures.

**Validation:** minimal strict scripted `AdapterTransport` / `UdsRequestLink` / `KwpRequestLink` fakes, source-derived byte-for-byte fixtures, targeted tests, negative cases, exact provenance. No required virtual ELM/STN adapter or simulated ECU network. No BMW test fleet requirement, no unsupported claim of universal physical compatibility.

**New merge testing:** verify target rebinding, source-specific KWP NRCs, actuator cancellation/cleanup, service mileage bounds, Garage profile state, authenticated backend sessions and store binding, Apple CI. PR #1 reported 91 Flutter/22 backend tests but this package did not rerun those tests. Keep separate status for static source verification, local test pass, CI pass and hardware validation.

**AI:** Read-only guide, no raw arbitrary ECU commands; preserve original one-time entitlement independently from future AI subscription. Do not remove original functions merely because their runtime behavior still needs independent verification.

**Deliver for each issue:** minimal diff, source/provenance, independent golden fixture, targeted test command/output, any residual risk, updated issue state. Do not claim completion based solely on an earlier PR description.
