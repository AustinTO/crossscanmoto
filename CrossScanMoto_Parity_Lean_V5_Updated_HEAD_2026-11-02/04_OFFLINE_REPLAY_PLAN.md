# Offline parity testing, without a full adapter or ECU emulator

## Principle

Test the behavior CrossScanMoto *actually implements* at existing abstraction boundaries. A fake needs only emit the responses listed in the fixture for a selected action. Unexpected commands must fail loudly. Never write a general-purpose AT/ST command interpreter, CAN/ISO-TP stack, model state engine or pretend firmware simply to support tests.

## Test levels

1. **Source-derived golden:** Translate original DEX/native method behavior to explicit input, emitted requests, expected decoded output/errors and state changes. Include artifact SHA and original class/method/offset. Independent reviewer confirms expected bytes were not generated from new Dart implementation.
2. **Protocol semantic unit tests:** Feed recorded reply byte arrays into mock `UdsRequestLink` / `KwpRequestLink`; verify command order, returned values, NRC/status handling, cleanup and scoping.
3. **Minimal transport stream replay:** For framing, queue only necessary ELM/STN lines and prompts into a fake `AdapterTransport`; test echoed commands, fragmented `>` prompts, timeouts and disconnect. This is **not** a full ELM emulator.
4. **Cross-layer replay:** From a selected UI action through `DiagnosticSession` and transport fake to UI result, verify state transitions and no unauthorized writes. Use immutable fixtures.
5. **Optional original-app differential:** Only when static evidence is insufficient, execute legitimately accessible original implementation in an isolated environment and capture a narrow behavior path. Do not bypass purchases, cryptography, ECU security or anti-tamper.
6. **Optional physical sampling:** Limited adapters/bikes can expose field quirks. This is separate from source/software parity and not a per-model prerequisite.

## Required source matrix

- **UDS** (`protocol_setup.dart`, `uds_client.dart`): original enum-18 setup, adapter STN branches, UDS 0x22/0x19/0x14, malformed frames, original 0x78 policy and response layout. Do not assume ISO-TP feature support beyond evidence.
- **Classic** (`kwp_client.dart`, original ordinal 13-17): KWP/KWA/KWA2/FTE initialization, 0x18/0x17/0x1A, timing and negative responses, original ABS variants.
- **DTC**: same code on distinct ECU keys, 24-bit and classic 16-bit formats, preserved status and source confidence.
- **Parameters**: 230 request parents / 486 result-row occurrences; probe signedness, offset, byte order, scale, units, enums, unsupported format, short payload. Source-derived decoder fields only.
- **Actuators**: 44 recovered definitions / 61 positions / 130 commands; only selected ECU; timed sequence and cleanup Off/End even after failure; no claim physical movement.
- **Maintenance/coding**: source-backed UDS E12B/E12C/E12D and legacy 0x3B variants; invalid mileage and date; positive ACK, readback mismatch, partial write; draft versus real coding.
- **Identity**: 84 recovered vehicle records and platform/group associations; no VIN false identity from weak addresses; original selected target only.
- **Adapter/mobile**: Android SPP, iOS real BLE GATT, TCP and optional relay lifecycle, permissions, error classification; do not treat Bluetooth Classic LX as generic iOS BLE.
- **AI**: read-only evidence snapshots, source citation IDs, missing/unknown values, subscription separation.

## Suggested minimal fixture schema

Each fixture includes `id`, `reference.source_version`, `reference.sha256`, `reference.method`, `reference.offset`, `scope.ecu_key`, `scope.protocol`, `expected_requests`, `scripted_replies`, `expected_outcome`, `evidence_kind`, `limitations`. Commands are for **test replay only**, not the AI generator. Fixtures may contain immutable original-derived payloads but do not copy entire proprietary library contents.

## Runner and reporting

Use `flutter analyze`, `flutter test` and targeted `dart test`/existing standalone checks. Add a fixture-driven Dart test harness and an evidence ledger. CI should mark only `PASS`, `FAIL`, `UNRESOLVED`, `NOT_APPLICABLE` for each scoped reference-supported branch, and distinguish `STATIC_GOLDEN`, `ORIGINAL_EXECUTED`, `TRANSPORT_REPLAY_E2E`, `SYNTHETIC_STRESS`, `BIKE_SAMPLED`. A scripted response generated from the new Dart algorithm is a **self-oracle**, not parity proof.

## Stop conditions

If needed reference binaries are unavailable locally, do not guess. Use existing documented offsets and published native table extraction provenance, then mark what remains unresolved. Continued reverse engineering is a task, not an excuse to permanently narrow the advertised app. Correct safety-critical operations may remain gated until enough original evidence establishes target and command ordering. Report that as a specific gap, not as blanket removal of the feature family.
