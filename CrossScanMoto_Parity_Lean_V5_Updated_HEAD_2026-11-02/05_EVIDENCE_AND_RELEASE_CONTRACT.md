# Capability and release evidence contract

**Separate scope, implementation and evidence.** Never equate listed model/ECU metadata with a function verified on a physical BMW.

`reference_state`: `OBSERVED_IN_ORIGINAL`, `SOURCE_INFERRED`, `NOT_OBSERVED`, `DIFFERS_BY_VERSION`.

`implementation_state`: `NOT_STARTED`, `PARTIAL`, `COMPLETE`, `REQUIRES_RECONSTRUCTION`, `INTENTIONALLY_UNAVAILABLE` (with source rationale).

`offline_evidence` (multi-valued): `STATIC_GOLDEN`, `ORIGINAL_EXECUTED`, `TRANSPORT_REPLAY_E2E`, `SYNTHETIC_STRESS`.

`real_world_evidence`: `NOT_TESTED`, `ADAPTER_SAMPLED`, `BIKE_SAMPLED`; manufacturer service guidance is documented scope evidence, **not** equivalent to motorcycle communication testing.

`action_safety`: `READ_ONLY`, `USER_CONFIRMED_WRITE`, `WORKSHOP_CRITICAL`, `NOT_EXPOSED`.

`parity_result`: `PASS`, `FAIL`, `UNRESOLVED`, `NOT_APPLICABLE`.

**Evidence required for PASS:** selected vehicle and original platform, ECU key/function flag, reference method/offset and artifact SHA, expected bytes/parse behavior derived independently of new implementation, exact Dart path, passing targeted test and known limitations. A fixture with guessed expected responses cannot receive `PASS` for reference parity.

**Release language:** “software implementation replayed against original-source-derived cases” is defensible; “confirmed to work on every supported BMW motorcycle” is not. Physical test results and hardware exclusions remain separate.

**Rights/safety:** Preserve provenance, avoid including original APKs/binaries or copyrighted manuals in deliverable, and have legal/licensing reviewed before distributing recovered proprietary tables/strings. No access-control/license/security bypass. No AI-generated control frames or bypass of explicit owner confirmation for ECU writes.

See `examples/capability_evidence_record.json` and `examples/source_derived_fixture.json` for JSON examples.
