# MotoScan Parity Ledger

Artifacts: MotoScan 1.110 & MotoScan 1.83 (K-Line / KWP); SHA-256 hashes recorded in `apk-findings.md` and `historical-protocol-1.83.md`.

| Area | Recovery | Implementation | Validation |
|---|---|---|---|
| TCP adapter byte transport | DEX Socket call sites recovered | Connect, write, disconnect, and app integration | Static analysis; automated test passes |
| ELM command framing | Prompt and CR command design | Serialized frames, timeout isolation, prompt synchronization | Standalone checks pass (`check_transport.dart`) |
| Adapter identity and voltage | ATI / ATRV observed in socket class | Native TCP connection screen, live telemetry gauge | Unit test & widget test pass |
| Bluetooth Classic | SPP UUID and RFCOMM paths recovered | Android paired-device SPP, permission flow, channel bridge | Static analysis & mock bridge |
| Adapter vendor detection | Identification branches recovered | ATI gate, WGSoft / OBDLink / vLinker identity branches implemented | Standalone checks pass (`check_adapter_profile.dart`) |
| BMW Modern UDS / D-CAN | BMW UDS setup and single-token framing traced in DEX | Explicit ECU/address UDS configuration, link, and bus protocol setup implemented | Synthetic fixture checks pass (`check_protocol_setup.dart`) |
| BMW Legacy KWP2000 (K-Line) | Fast init (`0x81`), 5-baud init, and KWP packet framing recovered from 1.83 | Full `KwpLink` and `KwpClient` with probe, DTC read/clear, and parameter routines | `kwp_client_test.dart` & `legacy_kwp_page_test.dart` pass (21 tests) |
| ECU identification | ECU-scoped tables and request metadata recovered | Full BMW Motorrad ECU catalog (DME, ABS, KOMBI, ZFE, EWS, RDC, SAF/ESA, DWA, RAD) and automatic vehicle scanner | `AutoScanController` & `parity_features_test.dart` pass |
| DTC read / clear | UDS service 0x19 and 0x14 + KWP 0x18 and 0x14 | UDS/KWP report parsing, 24-bit BMW DTC database, status mask decoding, and confirmed clear controls | UDS/KWP unit tests & `parity_features_test.dart` pass |
| Live telemetry | Categories and embedded descriptions recovered | Real-time multi-category telemetry registry (Engine, Brakes, Cockpit, TPMS) with gauge cockpit, min/max tracking, and metric/imperial conversion | Unit tests & widget tests pass |
| Service / adaptations | Categories and routine controls recovered | Service resets (annual service date, distance interval, brake fluid), adaptations (throttle, lambda, exhaust flap, gear sensor) | `service_manager_test` & `parity_features_test.dart` pass |
| Actuators & output testing | Component identifiers and execution routines recovered | Bi-directional routine execution (`0x31 0x01` / `0x2F`): fuel pump, radiator fan (50%/100%), cluster needle sweep, exhaust flap, ABS valves | `recovered_actuators_test.dart` & `parity_features_test.dart` pass |
| Vehicle coding / backups | Definitions and easycoding schema recovered | TFT startup animations, lighting options, LED retrofits, display units, shift light RPM, and full snapshot backup & restore manager | Parity unit tests pass |
| Vehicle selection & persistence | Full BMW model lineup and production year ranges recovered | Model hierarchy (R, S, F, K, G, C series) with persistent vehicle profiles (VIN, mileage, notes) | Parity unit tests & dashboard widget tests pass |
| In-App purchase verification | StoreKit JWS & Google Play Billing Developer API v3 | Cloudflare Worker (`backend/worker`) with D1 replay protection, SHA-256 account UUID binding, and verification client | `purchases_test.dart` passes (6 tests) |
| Remote adapter relay | TCP LAN bridge with authentication and byte stream tunneling | `AdapterRelayServer` & `RelayAdapterTransport` with token authentication and channel multiplexing | `adapter_relay_test.dart` & `check_adapter_relay.dart` pass |
| Visual quality & UX | Modern automotive workshop cockpit | Multi-tab responsive interface (Garage, Systems, Live Data, Workshop, Adapter), radial gauges, custom motorcycle silhouette, and ECU inspection suite | UI render test and screenshot suites pass |

Adapter command literals and disassembly locations: `adapter-commands.json`.

---

## Verification Summary

- `flutter analyze` reports **0 issues**.
- `flutter test` reports all **67 tests passing**.
- `tool/check_transport.dart` passes fragmentation, echo filtering, queue ordering, timeout, and late response rejection.
- `tool/check_uds.dart` passes UDS positive responses, response pending, and malformed rejection.
- `tool/check_protocol_setup.dart` passes command ordering, adapter guards, identifier formatting, and payload framing.
- `tool/check_adapter_profile.dart` passes traced initialization order and identification branches.
- `tool/check_adapter_relay.dart` passes relay authentication, raw byte forwarding, exclusivity, and lifecycle cleanup.
- `tool/check_recovered_catalog.dart` passes vehicle and ECU counts (84 models, 29 ECU groups) and cross-table references.
