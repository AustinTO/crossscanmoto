# CrossScanMoto parity-first V5 | merged HEAD correction

This package **supersedes V4**, which missed the merged PR #1. Pinned verified `main` on 2026-11-02: `adf98d171d0c828e60e6d7cf6fbb4d06e87c9437` (old `ceee4cbb4c116f807db4f8fa93873e94b1907f0c`). 47 original tickets preserved and annotated, plus 6 new integration/regression tickets = **53**. The current code was not modified by this package.

1. `00_START_HERE.md` is the lean entrypoint. `08_HEAD_MERGE_DELTA.md` explains what merged, what is partially fixed, and what remains.
2. `02_LEAD_AGENT_PROMPT.md` is the copy/paste instruction. `tools/task_packet.py` emits minimal single-ticket prompts **with corrected HEAD status**.
3. `reference/ISSUE_TRACKER.csv` is the authoritative status ledger. `reference/01_FULL_CHECKLIST.md` provides complete scopes. `09_MERGE_TEST_COMMANDS.md` gives targeted regression commands.
4. Older `knowledge/` research is still available but `knowledge/docs/APP_REPOSITORY_AUDIT.md` is a **pre-merge historical snapshot**, not the present HEAD.
5. No full virtual ELM/STN adapter or BMW ECU emulator is required. Scripted transports + source-derived fixtures, selective original-program execution, original source reconstruction and tests remain the plan.

Ticket distribution: {"merged_verify_only": 3, "open_unverified": 31, "partial_merge_remaining": 19}. Source code findings were inspected through the connected GitHub repository at pinned SHA. Passing PR-reported test counts are not claimed as independently re-run.
