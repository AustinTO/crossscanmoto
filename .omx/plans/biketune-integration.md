# Biketune catalog and operations integration plan

## Objective and boundaries
Integrate the recovered Biketune 1.9.1 catalog into CrossScan with explicit model/ECU identity, operation applicability, and diagnostic execution. The live catalog is `assets/research/biketune-live/library.decrypted.db`; it passed SQLite integrity checking and contains key-related tables. The private repository does not make secrets safe to distribute in the app. Treat catalog definitions and sensitive keys as separate assets; never embed keys in client builds.

## Current evidence
- `lib/diagnostics/vehicle_catalog.dart` uses name-based profiles and a curated list; recovered catalog has 83 bikes, 128 market models and 258 variants. Names alone cannot distinguish generations.
- `lib/diagnostics/ecu_catalog.dart` and `lib/diagnostics/auto_scan_controller.dart` route using MotoScan-derived platform IDs and ECU keys, not Biketune IDs.
- `lib/diagnostics/bmw_coding_engine.dart` implements a different DID/offset coding schema; physical writes default off. Biketune coding rows use CAFD root/version, register and bit fields.
- `lib/diagnostics/recovered_actuators.dart` requires on/off pairing. Biketune service steps additionally include prompts, timing, repeat and hold/stop actions. The catalog alone does not establish security, session, transport, or firmware preconditions.
- `lib/recovered_coding_panel.dart` snapshots are temporary, not durable restore points.

## Implementation stages
1. **Inventory and provenance.** Create a versioned, deterministic exporter reading the recovered DB in read-only mode. Explicitly allowlist tables/columns needed for bikes, variants, ECUs, coding, adaptations, actuators and service steps; exclude key-related and user/account tables. Emit schema version, source SHA-256, enabled/disabled status, row counts and unresolved references. Verify all 41 source tables are either included or explicitly excluded. Keep a manifest of omissions.
2. **Identity and migration.** Introduce stable source-qualified model, variant and ECU IDs. Preserve chassis, display names, years, experimental/disabled status and protocol separately; never infer missing fields. Migrate existing name-based garage profiles without silently selecting among ambiguous matches. Update `lib/main.dart` and `lib/diagnostics/vehicle_catalog.dart` for variant selection and persist exact identities.
3. **ECU applicability and transport.** Build a source-qualified bike→ECU→variant catalog using `bike_ecus`, `ecus` and variant records. Map addresses and protocols only when evidence establishes their meaning. Update `ecu_catalog.dart`, `auto_scan_controller.dart` and protocol setup to reject unknown or ambiguous targets instead of defaulting to a generic address/protocol. Show unsupported and experimental coverage accurately.
4. **Read-only discovery.** Add catalog-driven ECU identification, coding metadata and service/actuator listings with explicit eligibility states. Match actual hardware/firmware/CAFD identity before presenting an operation as applicable. Preserve unknown versus unsupported and do not treat catalog presence as hardware support.
5. **Coding architecture.** Implement a separate CAFD/register adapter rather than coercing rows into the existing DID schema. Derive read/write block mappings, bit ordering, value encoding, sessions, authorization, firmware applicability and reset/readback from demonstrable operation evidence. Reject ambiguous masks and unrecognized versions. Add durable, integrity-checked backups bound to VIN, ECU identity, version and original bytes; verify current blocks before writes, constrain changed bits and report partial failure.
6. **Service and adaptations.** Model the 397 service steps as a typed state machine supporting instructions, prompts, routine requests, positive responses, delays, repeat, hold/stop, cancellation and power cycles. Implement only kinds whose semantics and ECU routing are evidenced. Adaptation read/reset operations must use ECU-specific applicability, session and response validation.
7. **Actuators.** Map each enabled ECU-scoped actuator to its exact request/response and stop pair; use the existing serialized executor and ensure stop on timeout, error and cancellation. Mark entries without an established stop or protocol unsupported.
8. **UI and recovery.** Expose eligibility, preconditions, progress, cancellation and honest failure/partial-write states. Prevent concurrent diagnostic writes and retain operation audit records without account credentials or key material. Offer durable export/restore only after integrity and identity checks.
9. **Coverage ledger and release.** Produce a per-model, ECU and function matrix with counts for imported, mapped, executable, unsupported and unverified entries. Keep write execution gated per operation until its complete protocol and preconditions are established; catalog inclusion alone must not enable writes.

## Acceptance and verification
- Exporter produces reproducible output, accounts for every source table and foreign-key reference, excludes key tables, and does not ship the decrypted source DB in app bundles.
- Every selectable variant retains unique identity across save/reload; legacy profiles resolve deterministically or require selection. K46 and CE 04 regression cases pass.
- Unknown platform, address, protocol, ECU version or operation fails closed; test collisions and malformed records.
- Coding tests cover multi-byte fields, bit preservation, variant mismatch, stale blocks, backup tampering, interrupted writes and readback mismatch using a scripted adapter.
- Service tests cover every supported step type, sequence, delays, negative responses, timeout, cancellation, hold/stop and partial completion. Actuator tests verify stop on all exits.
- Run `flutter analyze --no-pub`, relevant unit/widget suites, full `flutter test`, exporter integrity/coverage checks and integration tests against deterministic UDS/KWP replay fixtures. Record evidence and limitations in the coverage ledger.
- Real-vehicle or bench verification is required to claim physical compatibility or enable each write; software tests cannot prove firmware behavior. Until then the UI identifies the limitation.

## Risks and dependencies
The database contains sensitive keys; repository privacy does not prevent accidental distribution or history exposure. Third-party data provenance and redistribution rights must be resolved before shipping. Unknown firmware/security behavior, incompatible protocols and incomplete service step semantics can cause incorrect ECU changes; preserve operation gates rather than fabricate mappings. Changes to model identity require backward-compatible profile migration.
