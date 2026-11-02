# RE-07: bounded offline replay

Started against `eccae2fb1d097fff0ee0f4fa2e8e74d2ce536845` on 2026-11-02.
The audited baseline was `ceee4cbb4c116f807db4f8fa93873e94b1907f0c`;
two intervening commits changed account authorization and diagnostic state safety.
The supplied V4 package was untracked and its progress/findings ledgers were empty.

V5 refresh: the checkout was subsequently fast-forwarded to merged main
`adf98d171d0c828e60e6d7cf6fbb4d06e87c9437`. The full local suite passed
99 tests, including these eight replay tests. The V4 baseline above records
startup history only; use merged main for all outstanding code-change status.

## Implementation and provenance

- `test/support/scripted_adapter_transport.dart`: ordered, exact ELM commands
  and explicit response fragments; no adapter firmware or ECU simulation.
- `test/support/scripted_request_links.dart`: strict UDS/KWP request queues.
- `test/replay_support_test.dart`: focused replay and failure-path checks.
- `test/fixtures/kwp_setup_1_83.json`: independent command-order expectation
  transcribed from the existing historical research, not generated from Dart.

Fixture provenance is MotoScan 1.83, `i3/g.c0`, APK SHA-256
`f4b168234e2b3a042f35f3c0e8ee27a19e47bec0b32d01f1d6efa235ab39eacc`.
The retained source is documented in
`assets/research/historical-protocol-1.83.md`, section “ELM framing and parity
implementation.” That note supplies the six setup commands and acceptance
rule (response contains `OK`). The fixture instantiates the address template
with `0x12`; this does not establish an ECU/model mapping. This pass reused
the research note; it did not reverify the historical APK or execute the original.

`OK` fragments and application response samples are synthetic regression data.
There is no captured original response transcript in this fixture. The original
method byte offset and complete ECU applicability are not retained here.

## Evidence boundary

Reference state: `SOURCE_INFERRED`. Offline evidence: `STATIC_GOLDEN` for
the command sequence only, `SYNTHETIC_STRESS` for response/error mechanics.
Real-world evidence: `NOT_TESTED`. Action safety: test-only; no hardware writes.
Full reference parity result: `UNRESOLVED`.

RE-07 remains partial under the V4 acceptance contract until independently
source-derived application reply goldens and their complete provenance are
retained. Do not promote synthetic replies to original-executed evidence.
Reuse the helpers for additional tickets; avoid expanding this into an emulator.
