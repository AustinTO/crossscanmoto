# P0-05 service dispatch oracle progress

Status: **COMPLETE (UDS 12-Route Scope)**. The source evidence identifies 12 UDS
`CF_SERVICE` keys and three legacy KWP `qr`/`rr` response-label routes.
Static dispatch goldens and strict replay tests have been emitted and verified:
57 replay tests pass in `test/service_source_replay_test.dart`.

## Scoped artifacts

This lane owns the following artifacts:

- `test/fixtures/service_dispatch_goldens.json` (created and verified)
- `test/service_source_replay_test.dart` (created and 57/57 tests passing)
- `tool/native/build_service_goldens.py` (created and generated)
- This progress note

The production API remains owned by the runtime implementation lane. The new
`BmwServiceResetProtocol` / `BmwServiceManager` `shouldAbort` callback is in
place, with typed cancellation carrying confirmed writes and completed
readback. Strict replay fakes already exist in
`test/support/scripted_request_links.dart`.

## Confirmed source templates

The source worker confirmed `sl0.C` at DEX `0x21fe78` builds UDS
`WriteDataByIdentifier` requests:

- E12B: `2E E1 2B` + hour, minute, second, day, one-based month, year BE
- E12C: `2E E1 2C` + day, one-based month, year BE
- E12D: `2E E1 2D` + low 16 bits of mileage, BE

The method uses a 2000 ms transfer timeout and sleeps 1500 ms after each
enabled operation. The original reads each write result but discards it; its
later `sl0.r` refresh reads E119, E12B, E12D, E12C. The source note is
[`service-reset-recovery.md`](../../assets/research/service-reset-recovery.md);
the focused method excerpt is
[`service-C-sl0.txt`](../../assets/research/service-C-sl0.txt).

The source worker also confirmed separate KWP `qr.C` / `rr.C` 0x3B templates:

- P: `3B 10 00 00 00 00 00 00 00`, values in bytes 2–8
- Q: `3B 11 00 00 00 00`, values in bytes 2–5
- R: `3B 12 00 00`, mileage low 16 bits in bytes 2–3

Those handlers use 3000 ms and issue supported events in P, Q, R order. Their
exact per-key enablement, selected handler class, start/pre-read sequence and
readback remain unresolved; no per-key KWP golden will be emitted yet.

## Confirmed UDS route set

[`P0-05-service-dispatch-evidence.md`](P0-05-service-dispatch-evidence.md)
records 11 exact `G_MRKOMB` response-ID → ECU-key selections and one
`G_MRSLZ` → `cuX_CCP` selection. All 12 corresponding `FUNCTIONS` rows have
numeric type 12 (`CF_SERVICE`) enabled, and their controller descendants
inherit `sl0.C`. Example: `cuX_KOMB18` uses raw row
`12;1;0;0;0;0;49701`, group 276 (`G_MRKOMB`), response ID 1019968, and an
`i15`/`sl0` path. Raw database `defaultprotocolid` values remain raw IDs; the
observed handler sends UDS `0x2E`/`0x22` requests.

The 9 `CF_SERVICE_FUNCTIONS` keys are still being traced to exact groups,
controller branches, and service actions. They are not merged into the
`CF_SERVICE` route set by name.

The legacy controller path is distinct: `D_MRKOMB` selects `cr(6)` at address
96; response IDs 26640 → `qr`/`MRKOMB18`, 24832 → `rr`/`MRKOMBI`, and 24848 →
`rr`/`MRKOMB46`. This binds factory response labels to legacy KWP handler
classes, but does not join those labels to the ECU-scoped `FUNCTIONS` flags.
Keep legacy tests unresolved until their action bodies and gates are pinned.

## Cancellation test plan

The runtime API accepts `shouldAbort`; preflight cancellation sends zero
requests, while cancellation after a held first ACK records only that confirmed
DID and issues no later writes or readbacks. The strict scripted links support
these tests. All 57 tests in `test/service_source_replay_test.dart` pass,
covering all 12 UDS routes, SI_ALL, SI_DATE, SI_MILEAGE, SI_DATE_CAR, NRC
rejection, readback failure, mileage bounds, cancellation before write,
cancellation after first ACK held, and fail-closed legacy routing boundary.
