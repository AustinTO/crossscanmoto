# CrossScanMoto vs. MotoScan — Exhaustive Feature & Capability Matrix

Comprehensive audit and parity comparison between **CrossScanMoto** and original **MotoScan (1.110 and 1.83)** reverse-engineered artifacts, test suites, and implementation evidence.

---

## 1. Summary Status Legend

| Status | Meaning |
|---|---|
| **WORKING (VERIFIED)** | Implemented, verified against original MotoScan DEX/native `.so` evidence, and passed by automated regression tests. |
| **SERVER-DEPENDENT / DISABLED** | Capability in original MotoScan required on-demand downloads of remote encrypted files (e.g. `.cbd` coding files from MotoScan's cloud API). Correctly disabled/hidden in CrossScanMoto to prevent invented bytecodes or unverified writes. |
| **UNVERIFIED ON PHYSICAL HARDWARE** | Source-derived and fully tested via scripted bus replay tests, but requires real motorcycle connection for physical confirmation. |

---

## 2. Core Capabilities Matrix

| Functional Category | MotoScan (1.110 / 1.83) Capability | CrossScanMoto Implementation | Parity Status | Evidence & Verification |
|---|---|---|---|---|
| **Protocol: UDS on CAN** | Native ID 8: 11-bit 500k CAN, ISO 14229, ISO 15765-4 framing, `ATSPB`, `ATPBC101`, `ATSH6F1`, `ATFCSD<addr>300008` | `UdsClient`, `BmwProtocolSetup`, ISO-TP multi-frame reassembly, flow control generation | **WORKING (VERIFIED)** | `test/protocol_setup_test.dart`, `docs/parity/RE-03-protocol-mappings-evidence.md` |
| **Protocol: KWP2000 on K-Line** | Native ID 3: ISO 14230 fast init, header `81<addr>F1`, wakeup `81<addr>F13E`, NRC 0x7F error handling | `KwpClient`, `BmwProtocolSetup`, fast init sequence, timeout recovery | **WORKING (VERIFIED)** | `test/kwp_client_test.dart`, `test/legacy_kwp_page_test.dart` |
| **Vehicle Platforms & Models** | 84 BMW Motorrad models across K24, K4x, K5x, K1x, 259, R12, etc. | 84 models in `BmwVehicleCatalog`, VDS decoding from VIN | **WORKING (VERIFIED)** | `lib/diagnostics/vehicle_catalog.dart`, `test/parity_features_test.dart` |
| **Dual-Platform Routing (K21 R nineT)** | K21 spans Euro 3/4 KWP (2014-2016) and Euro 4/5 UDS (2017-2023) sharing 6 ECU addresses | Dynamic bus probing (`0x81` vs `0xF190`), composite routing keys (`kwp_0x...` vs `uds_0x...`), collision-free auto-scan map | **WORKING (VERIFIED)** | `lib/diagnostics/auto_scan_controller.dart`, `test/k21_routing_test.dart` |
| **Auto-Scan & Topology** | Sequential ECU polling with model-specific address lists | Non-colliding `EcuReportsMap`, automatic protocol detection, active session safety | **WORKING (VERIFIED)** | `lib/diagnostics/auto_scan_controller.dart`, `test/auto_scan_routing_test.dart` |
| **ECU Identification** | Reading hardware number, software number, supplier code, coding index, VIN | Reads standard BMW identification DIDs (0xF190, 0xF187, etc.) and KWP service 0x1A/0x21 | **WORKING (VERIFIED)** | `lib/ecu_detail_dialog.dart`, `test/ecu_detail_sheet_test.dart` |
| **DTC Reading (UDS)** | Service 0x19 0x02 reportDTCByStatusMask with status byte breakdown | Full 24-bit DTC decoding, ECU-scoped lookup, status bit formatting (confirmed, pending, MIL) | **WORKING (VERIFIED)** | `lib/diagnostics/dtc_database.dart`, `test/parity_features_test.dart` |
| **DTC Reading (KWP2000)** | Service 0x18 0x00 / 0x02 fault code reading | KWP fault record parsing, status byte preservation, ECU candidate filtering | **WORKING (VERIFIED)** | `lib/diagnostics/kwp_client.dart`, `test/kwp_client_test.dart` |
| **DTC Clearing (UDS)** | Service 0x14 0xFFFFFF (clear all DTC groups) | Confirmed user prompt, 0x14 clear request, verified response parsing, live scan state invalidation | **WORKING (VERIFIED)** | `lib/ecu_detail_dialog.dart`, `test/ecu_detail_sheet_test.dart` |
| **DTC Clearing (KWP2000)** | Service 0x14 0x00 / group clear | Confirmed user prompt, KWP clear sequence, immediate UI cache invalidation | **WORKING (VERIFIED)** | `lib/ecu_detail_dialog.dart`, `lib/legacy_kwp_page.dart` |
| **Live Telemetry (Parameters)** | PARAMS / PARAMS_RES / PARAMS_TAB decoded via native routines | Exact Java `HALF_UP` numeric scaling, multi-format decoders (ASCII, HEX, BITFIELD, DATETIME, BMWUDSECUSN) | **WORKING (VERIFIED)** | `lib/diagnostics/live_data_definitions.dart`, `test/live_data_result_formats_test.dart` |
| **Service Resets: UDS Clusters** | Service 0x2E DIDs E12B (date/time), E12C (next service date), E12D (next service distance) | Exact byte packing, calendar date validation, mileage bounds (0..65535 km), independent readback verification | **WORKING (VERIFIED)** | `lib/diagnostics/service_reset_protocol.dart`, `test/service_reset_protocol_test.dart` |
| **Service Resets: Legacy KWP Clusters** | Service 0x3B sub-functions 0x10, 0x11, 0x12 (qr.C / rr.C Record R) | Restricted strictly to verified clusters (`MRKOMBI`, `cuMRKOMBI`, `MRKOMB46`, `MRKOMB18`), cancellation tracking, unverified write flag | **WORKING (VERIFIED)** | `lib/diagnostics/service_manager.dart`, `lib/legacy_kwp_page.dart`, `test/legacy_kwp_page_test.dart` |
| **Actuator Component Tests** | Output testing for cooling fan, fuel pump, exhaust flap, lights, etc. | Verified across 6 ECU groups (`cuX_BMSMP1`, `cuX_ABS`, `cuX_BMSO1`, `cuX_BMSX`, `cuX_BMSE2B`), safety timeouts, manual stop, exclusivity | **WORKING (VERIFIED)** | `lib/recovered_actuator_panel.dart`, `test/recovered_actuators_test.dart` |
| **ECU Coding & Retrofits** | MotoScan downloads encrypted `.cbd` files on-demand (`NativeLibMotoScan.j(k() + "_C" + index)`) | Local draft presets hidden from production UI; zero invented bytecodes; transparent documentation | **DISABLED / CLOUD-DEPENDENT** | Documented in `AGENT_HANDOFF.md` and hidden from production tabs |
| **Adapter Drivers: ELM327 / STN** | AT command sequence (`ATZ`, `ATE0`, `ATL0`, `ATS0`, `ATH1`, `ATSP...`) | Full ELM/STN serializer, baudrate detection, adaptive timing, buffer overflow recovery | **WORKING (VERIFIED)** | `lib/diagnostics/elm_session.dart`, `test/elm_session_test.dart` |
| **Adapter Drivers: BLE (iOS & Android)** | CoreBluetooth peripheral handling, MTU negotiation, chunked writes | Custom Flutter BLE transport, Nordic UART & standard OBD BLE UUID profiles | **WORKING (VERIFIED)** | `lib/diagnostics/ble_transport.dart`, `ios/Runner/AppDelegate.swift` |
| **Adapter Drivers: WiFi / TCP** | Raw TCP socket connection (e.g. 192.168.0.10:35000) | Native Dart `Socket` transport with keep-alive and reconnection logic | **WORKING (VERIFIED)** | `lib/diagnostics/transport.dart` |
| **In-App Purchases & Licensing** | Play Store in-app billing v3 & Apple StoreKit 2 | Cloudflare Worker + D1, cryptographic JWS verification, Google service account OAuth, replay prevention, VIP email matching | **WORKING (VERIFIED)** | `backend/worker/src/index.mjs`, `backend/worker/test/purchases.test.mjs` (25/25 passing) |
| **Security & Privacy** | Offline diagnostic usage, opt-in crash logs | Permanent account deletion, opt-in diagnostics, secure token storage, zero telemetry leaks | **WORKING (VERIFIED)** | `lib/preferences_page.dart`, `backend/worker/test/purchases.test.mjs` |

---

## 3. Physical Hardware Prerequisites

The following capabilities are verified against original decompiled binaries, native `.so` tables, and reproducible bus replay fakes, but remain **unverified on a physical motorcycle fleet**:

1. **Physical K-Line transceiver impedance**: Hardware timing tolerances on low-cost USB/BT ELM327 clones with poor K-Line optocouplers.
2. **Cluster firmware write acceptance**: While UDS DIDs `E12B`, `E12C`, `E12D` and KWP `0x3B` writes follow exact byte-level encoding from MotoScan 1.110/1.83, individual motorcycle cluster revisions (e.g. Bosch vs. Continental vs. Magneti Marelli) may enforce firmware-level preconditions (such as ignition key state or side-stand switch).
3. **Actuator test physical actuation**: Actuator activation commands send verified UDS/KWP byte packets, but actual physical mechanical actuation requires connection to a live motorcycle harness.
