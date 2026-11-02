# High-value reverse-engineering queues (load by ticket only)

## Priority unresolved original paths

1. Native table factory routing: map `84 vehicle records -> series/platform -> 29 ECU groups -> observed ECU keys -> protocol/factory handler -> enabled FUNCTIONS`. Preserve duplicates and ambiguous keys. Research basis: `native-data-findings.md`, `native-schema-recovery.md`, native pointer-table extractors.
2. UDS setup/framing: inspect `vq4.x` enum-18 branch and `yl4.v`. Current Flutter link accepts one token and explicitly rejects `NRC 0x78`. Do not “fix” by inventing multi-frame behavior; reconstruct actual original adapter contract.
3. KWP/KWA/KWA2/FTE: ordinal 13-17 branches and old ABS handlers. 1.83 older implementation provides useful evidence but track version differences.
4. `PARAMS_RES` decoder: signedness, offset, dividers, multipliers, enums, units and `PARAMS_TAB_GLOBAL`. 486 result rows require per-type source-backed decode; labels alone are insufficient.
5. Legacy service resets: `qr`/`rr` 0x3B and original UDS `sl0.C` E12x with 16-bit service interval guard. Confirm correct ECU-key factory dispatch.
6. Real coding: investigate original `easycoding`, command request/response methods and persistence; avoid calling Flutter local draft “motorcycle coding.”
7. Native table failed probes: 130 failures were extraction attempts, not proof original features missing. Reprobe in bounded, reproducible batches rather than feeding logs to an LLM.
8. DTC collision/resolution: 5,805 rows scoped by ECU, exact localization joins and status, no generic model-wide fault description guessed.

## Avoidable high-cost work

Do not reconstruct the entire ELM/STN firmware, ISO-TP adapter stack or full BMW simulator unless a narrowly documented blocker and cost-benefit analysis shows a particular operation truly cannot be tested at existing abstractions. Optional original-app dynamic I/O hooks are similarly narrow, not a blanket CI prerequisite.

## Original source locations already recorded in repository

- `assets/research/protocol-recovery.md`
- `assets/research/historical-protocol-1.83.md`
- `assets/research/native-schema-recovery.md`
- `assets/research/native-data-findings.md`
- `assets/research/service-reset-recovery.md`
- `assets/research/actuator-execution-recovery.md`
- `assets/research/parity.md`
- `assets/research/recovered-native/` (native-table extraction provenance)
- `tool/native/` (reproducible parsers/extractors)

Only access relevant sections for your assigned ticket. Existing research docs are evidence of past investigation, not a substitute for checking changed code at current HEAD.
