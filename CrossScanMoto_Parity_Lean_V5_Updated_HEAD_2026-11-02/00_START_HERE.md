# START HERE | CrossScanMoto V5 (merged-HEAD refresh)

**Repository:** https://github.com/AustinTO/crossscanmoto  
**Verified main HEAD on 2026-11-02:** `adf98d171d0c828e60e6d7cf6fbb4d06e87c9437`  
**Prior V4 audited SHA:** `ceee4cbb4c116f807db4f8fa93873e94b1907f0c`  
**Merge:** PR #1 "Fix diagnostic target safety, account security, and release builds" (2026-11-02).

**Goal:** Reproduce original MotoScan 1.110/1.83 software functionality, reconstruct missing DEX/native behavior, establish independently sourced golden replay tests. **Do not build a full ELM/STN adapter simulator or BMW ECU simulator.** Do not require physical testing with every supported BMW; physical behavior remains a separate confidence level.

**Critical:** V4 missed merged PR #1. The new code *already* implements some target-rebinding, KWP reply matching, actuator cancellation and serializing, mileage bounds, purchase authentication and release workflow improvements. Do NOT reimplement these from stale instructions. Use current status and `next_action` in the issue CSV.

## Minimal agent startup

1. Verify `git rev-parse HEAD` and compare it to `adf98d171d0c828e60e6d7cf6fbb4d06e87c9437`. If newer, run `git log --oneline adf98d171d0c828e60e6d7cf6fbb4d06e87c9437..HEAD`, inspect changed files, and refresh statuses before acting.
2. Read `08_HEAD_MERGE_DELTA.md`, then `01_EXECUTION_POLICY.md`. Do not preload all full research.
3. Run `python tools/task_packet.py --list` and `python tools/task_packet.py --id P0-07` (or assigned issue). Read only the cited repo files and relevant original analysis.
4. If task status is `merged_verify_only`, first run its regression tests and inspect code; **don't duplicate the merged implementation**.
5. Log confirmed findings and reusable golden tests in `state/` with exact commit and original-source offsets.

**Immediate still-open defects visible at merged HEAD:** `HEALTHY` status on DTC-free response, weak model inference, unscoped DTC descriptions in auto-scan, unvalidated live-data scaling, coding dropdown success claims despite local-only draft. See `08_HEAD_MERGE_DELTA.md`.

**Full plan:** `reference/01_FULL_CHECKLIST.md` (53 tickets). **Single task:** `tools/task_packet.py`.
