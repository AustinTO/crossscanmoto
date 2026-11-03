# Protocol Mapping Verification Evidence (RE-03 / Priority 2)

## 1. Overview
This document records the exact reverse-engineered source evidence from original MotoScan 1.110 and 1.83 DEX and native metadata proving the mapping and setup sequences for native `defaultprotocolid` 3 and 8, as well as the specialized KWA and FTE protocols.

## 2. Protocol Enumeration (`ox2`) in MotoScan 1.110 DEX
In MotoScan 1.110, the diagnostic transport protocol enum is `ox2`.
The relevant ordinals and protocol definitions recovered from `ox2.java`:

| Enum Constant | Ordinal | Protocol Name | ELM Setup Commands / Characteristics |
|---|---|---|---|
| `ox2.x` | 13 | `BMW_BIKE_KWA` | `ATPC`, `ATAL`, `ATSH81<addr>F3`, `ATWM81<addr>F33E`, `ATST50`, `ATSP5` |
| `ox2.y` | 14 | `BMW_BIKE_KWA2` | `ATPC`, `ATAL`, `ATSH80<addr>F3`, `ATWM80<addr>F33E`, `ATST50`, `ATSP5` |
| `ox2.X` | 15 | `BMW_BIKE_FTE_INIT` | `ATPC`, `ATAL`, `ATSH81<addr>F3`, `ATWM013E`, `ATST90`, `ATSP5` |
| `ox2.Y` | 16 | `BMW_BIKE_FTE_WORK` | `ATSH010000` (FTE proprietary ABS framing) |
| `ox2.Z` | 17 | `BMW_BIKE_KWP` | `ATPC`, `ATAL`, `ATSH81<addr>F1`, `ATWM81<addr>F13E`, `ATST60`, `ATSP5` |
| `ox2.s1` | 18 | `BMW_BIKE_UDS` | `ATSPB`, `ATPBC101`, `ATSH6F1`, `ATFCSH6F1`, `ATFCSD<addr>300008`, `ATFCSM1`, `ATCEA<addr>`, `ATCM7FF`, `ATCF6<addr>`, `ATST90`, `ATBI` |

## 3. Native `defaultprotocolid` Mapping

### Protocol ID 3: `BMW_BIKE_KWP` (`ox2.Z`)
Native `defaultprotocolid = 3` designates KWP2000 over ISO 14230-4 K-line:
1. Traced via `fx.I(String)` where factory initialization links protocol ID 3 to KWP controller subclasses.
2. Setup parameters:
   - Baud / Bus type: ISO 14230-4 K-line Fast Init (`ATSP5`)
   - Header: `ATSH81<addr>F1` (Target: ECU physical address; Source: Tester address `0xF1`)
   - Wakeup / Tester Present: `ATWM81<addr>F13E`
   - Timeout: `ATST60`
   - Target ECUs: Pre-2016 K-line controllers (BMS-K, BMS-KP, BMS-KP2, BMS-C, ABS-N, ABS-8M, DWA, MRKOMBI, ZFE).

### Protocol ID 8: `BMW_BIKE_UDS` (`ox2.s1`)
Native `defaultprotocolid = 8` designates UDS over ISO 15765-4 11-bit 500k CAN:
1. Traced via `cr.a()` and `br.d()`, `br.e()`, `br.f()` where protocol ID 8 is mapped directly to `ox2.s1`.
2. Setup parameters:
   - Protocol: ELM User 1 CAN 11-bit (`ATSPB`), Baudrate 500kbps (`ATPBC101`)
   - Functional / Transmit Header: `ATSH6F1` (Physical CAN identifier `0x6F1` or `0x600 + addr`)
   - Flow Control Filter: `ATFC SH 6F1`, `ATFC SD <addr> 30 00 08`, `ATFC SM 1`
   - CAN ID Acceptance: `AT CEA <addr>`, `AT CM 7FF`, `AT CF 6<addr>`
   - Timing: `ATST90`, `ATBI`
   - Target ECUs: Modern CAN bus / UDS controllers (BMS-X, BMS-MP, ABS-9M, ABS-9M+, KOMBI18, XBMS, XABS, etc.).

## 4. Specialized Fallbacks: KWA & FTE
- **MA2.4 Engine Controllers (`BMW_BIKE_KWA`):**
  Uses tester address `0xF3` (`ATSH81<addr>F3`) and tighter timeout `ATST50`.
- **FTE ABS Systems (`BMW_BIKE_FTE_INIT` / `BMW_BIKE_FTE_WORK`):**
  Uses dual-stage initialization. Stage 1 initializes communication via ISO 14230 K-line with wakeup `ATWM013E`. Stage 2 switches framing to raw byte stream with header `ATSH010000`.

## 5. Parity & Implementation In CrossScanMoto
CrossScanMoto encapsulates these exact protocol setup sequences and frame formats in `lib/diagnostics/protocol_setup.dart` and `lib/diagnostics/uds_client.dart` / `lib/diagnostics/kwp_client.dart`.
Vehicle series probe disambiguation (`lib/diagnostics/auto_scan_controller.dart`) explicitly verifies whether address 0x12 responds to KWP (Protocol 3, `ox2.Z`) or UDS (Protocol 8, `ox2.s1`), ensuring correct protocol assignment for dual-platform series such as K21.
