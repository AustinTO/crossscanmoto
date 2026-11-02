# Copy/paste worker template

Fix ticket `{TICKET_ID}` on latest `AustinTO/crossscanmoto` HEAD. Run `python tools/task_packet.py --id {TICKET_ID}` and inspect only listed source paths plus required call graph. Search `state/findings.jsonl` and committed golden tests first; continue original 1.110/1.83 reverse engineering if necessary. Build correct parity behavior, not a stub.

**Testing:** Reuse existing `AdapterTransport`, `UdsRequestLink`, `KwpRequestLink` seams; produce independently original-derived byte-level fixtures; inject wrong ECU, malformed reply, timeout, cancel or negative responses as relevant. No full virtual ELM/STN or BMW ECU simulator. No demand for real bikes. Label software/offline validation separately from hardware compatibility. Preserve scoped, explicitly confirmed ECU writes; AI stays read-only.

**Output:** changed paths, original method/offset/hash, fixture paths/kind, exact test commands/results, outcome PASS/FAIL/UNRESOLVED, unresolved work and next ticket. Write a <=200-word machine-readable checkpoint; do not paste giant logs or all repository files.
