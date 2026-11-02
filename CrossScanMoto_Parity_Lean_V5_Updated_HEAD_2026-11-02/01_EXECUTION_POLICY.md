# Execution and token-cost policy

- One coordinating agent tracks the 47 tickets, checks dependencies and merges work. Specialist workers get one scoped ticket and a few source paths, not the entire 47-ticket checklist.
- Before any new reverse engineering: check `state/findings.jsonl` and committed `docs/parity/` findings/fixtures. Reuse verified source offsets, decoded schemas and expected bytes.
- Default startup <~1,200 tokens, ticket payload <~650 tokens; read ~100-250 lines first. Expand only where necessary to establish correctness. Do not dump a 65 MB DEX inventory or a 480 KB generated DTC table into context.
- Use scripts (`rg`, `jq`, Python parsers and tests) to count, join, diff and validate large tables rather than model-reading every row.
- Use `AdapterTransport`, `UdsRequestLink`, `KwpRequestLink`, injectable clocks and request queues. Test only required AT/ST syntax and replies. **No full virtual ELM/STN firmware, CAN network or BMW ECU emulator.**
- Only source-derived or original-executed expectations may serve as parity goldens; synthetic tests are regression/stress evidence, not reference-parity proof.
- Source reverse engineering and optional isolated original execution should be *targeted*, triggered by an unresolved handler or disagreement. No need to instrument the original app for every action if exact control flow suffices.
- Escalate after two unchanged failing attempts with exact blocker and smallest disassembly/repro slice. Do not repeat broad prompts.
- Keep each worker handoff <=200 words plus paths, tests, source identifiers, status and unresolved cases. Store data in files, not long chat replies.
- Preserve all scope and ECU-write safety checks even when they cost additional analysis. Neither passing tests nor source reconstruction implies confirmed compatibility with every ECU software version.
- Track actual input/output tokens, cache hits and attempts if the provider exposes them; never assume a fixed savings percentage.


## V5: merged HEAD rule

PR #1 changed runtime and backend security behavior since V4. All task packets now contain `audit_status`, `merged_evidence` and `next_action`. Avoid scanning/re-reading the entire PR patch for every worker; MH-01 reviews it once and stores the result. A `merged_verify_only` issue must not be reimplemented by default. Check current HEAD vs `adf98d171d0c828e60e6d7cf6fbb4d06e87c9437` before every task batch, not on each file read.
