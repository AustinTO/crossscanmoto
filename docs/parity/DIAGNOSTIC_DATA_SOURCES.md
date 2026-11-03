# BMW Motorrad Diagnostic Data Sources & ECU Coding Architecture

## Executive Summary

This document resolves the diagnostic-data and ECU coding dependency investigation for CrossScanMoto, addressing:
1. **Priority 1: Reinvestigation of the MotoScan Coding-Data Dependency.** Conclusive disassembly and offline dynamic execution proof disproving the hypothesis that ECU coding requires proprietary encrypted `.cbd` files downloaded on demand from remote servers.
2. **Priority 2: Independent Diagnostic-Data Sources Evaluation.** A thorough legal, technical, and regulatory assessment of EU Regulation 168/2013 Article 57(6), BMW Motorrad AOS, EDIABAS CABD/SGBD architectures, public BMW CAN research, and competitor implementations (GS-911, Biketune).
3. **Recovery of Practical Coding Capabilities.** A source-verified parameter decoding, backup, and safe readback engine.

---

## 1. Resolution of the Coding-Data Dependency (Priority 1)

### 1.1 The Disproven Hypothesis
Previous reviews suggested that MotoScan's missing ECU coding functionality was blocked because coding definitions were held exclusively in encrypted `.cbd` files downloaded on demand from MotoScan cloud servers.

**This hypothesis is conclusively FALSE.**

### 1.2 The Proven Mechanism & Execution Trace
Reverse engineering of the original **MotoScan 1.110 APK** (classes DEX) and **`libmotoscan-helper.so`** (AArch64 native library, SHA-256 `bab0c173bb33c37262d07bbbbdc2c91213275d2a68e941d1b39fc3affd34fc71`) reveals the complete, offline execution path:

```
[Vehicle UDS Link]
        │
        ▼
   ECU Identification (0xF187 / 0xF190 / Z().b)
        │ Byte 0x02 = Coding Index (e.g. 0x04 -> "04")
        │ Short ECU Name = Lel0;.g (e.g. "KMBI_K25", "ZFE", "BMSK")
        ▼
   Key Construction: k() + "_C" + indexHex (e.g. "KMBI_K25_C04")
        │
        ▼
   NativeLibMotoScan.j(String key)
        │
        ▼
   Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_l (VA 0x6f7474)
        │ Converts jstring to std::string
        ▼
   Lookup Factory Function (VA 0x6fc750)
        │ String pattern matching for 48 ECU coding variants
        ▼
   Embedded String Tables (.rodata offset 0x2cd21c)
        │ Semicolon-delimited records (Record 00, 06, 12, 10, 09, 0A)
        ▼
   gx.n(String[] lines)
        │ Parses Record 06 (Blocks / DIDs) -> p90
        │ Parses Record 12 (Parameters) -> c53
        │ Parses Record 10 (Options) -> d53
        ▼
   pl0.a0() Read Coding Loop
        │ Iterates unique DIDs in block container p90
        │ Sends UDS 0x22 [ReadDataByIdentifier, DID_high, DID_low]
        │ Receives raw bytes (0x62) and decodes active bitfields
        ▼
   pl0.h0() Write Coding Loop (When edited)
        │ Iterates modified DIDs
        │ Sends UDS 0x2E [WriteDataByIdentifier, DID_high, DID_low, ...payload]
        │ Verifies positive response 0x6E
        │ Sends UDS 0x11 0x01 [ECUReset, HardReset] -> verifies 0x51
        │ Sleeps reboot_seconds * 1000 + 3000 ms
```

### 1.3 Data Provenance Matrix: What is Stored Where?

| Data Category | Storage Location | Recovery Proof / Reference |
|---|---|---|
| **Coding Schemas (48 variants)** | Embedded in `libmotoscan-helper.so` (`.rodata` offset `0x2cd21c`, factory `0x6fc750`) | Recovered 48 variants, 3,126 parameters, 8,990 options via offline QEMU probe (`tool/native/extract_native_coding_tables.py`) |
| **Parameter Bitmasks & Offsets** | Embedded in Record `12` strings (`12;NAME;DID;OFFSET;LEN;TEXTID;OPT_MASK;BITMASK;DEFAULT;`) | Fully extracted into `assets/data/recovered_coding_definitions.json` |
| **Option Names & Value Bytes** | Embedded in Record `10` strings (`10;OPTION_NAME;HEX_BYTES`) | Fully extracted into `assets/data/recovered_coding_definitions.json` |
| **Localized Option Labels** | Embedded in DEX string pools and native string tables | Recovered German & English option descriptors |
| **Downloaded / Cached `.cbd` Files** | **None.** No CBD network loader exists in MotoScan DEX or native code | Network client inspects only Play Store billing receipts and keyvault hash |
| **Remote Service Data** | MotoScan server handles license authentication only | No diagnostic data or ECU payloads are downloaded over HTTP/HTTPS |
| **Live Vehicle Coding State** | ECU internal non-volatile memory | Read live via UDS Service `0x22` using schema DIDs (e.g. `0x3005`, `0x300A`) |

### 1.4 Format Distinctions
- **CABD / CBD (EDIABAS)**: Compiled SGBD script tables historically used by BMW toolchains. MotoScan decompiled or extracted these tables into semicolon-delimited string constants embedded directly into `libmotoscan-helper.so`.
- **CAFD / NCD (Esys)**: XML/binary coding descriptions introduced with BMW F-series automotive Ethernet/DoIP architectures. BMW Motorrad **never used CAFD/NCD** on K24, K25, K46, or K50 platforms.
- **CrossScanMoto Recovered Format**: Structured JSON catalog (`assets/data/recovered_coding_definitions.json`) containing complete block DIDs, byte offsets, bitmasks, and option values.

---

## 2. Independent Diagnostic Data Sources (Priority 2)

### 2.1 EU Regulation 168/2013 Article 57(6) (Right to Repair for Diagnostic Tools)
Under **Regulation (EU) No 168/2013 of the European Parliament and of the Council** (on the approval and market surveillance of two- or three-wheel vehicles and quadricycles), **Article 57(6)** establishes clear rights for independent diagnostic tool manufacturers:

> *"Manufacturers shall make available to interested manufacturers of diagnostic, service and repair tools and equipment, in a non-discriminatory way, components and diagnostic tool information, including vehicle communication protocols, electronic control units diagnostic identifiers, and software updates required to diagnose and service vehicles."*

**Key Takeaways for CrossScanMoto:**
1. BMW Motorrad is legally obligated under EU law to provide non-discriminatory technical access to diagnostic communication protocols and ECU diagnostic identifiers (DIDs) to independent diagnostic tool developers.
2. CrossScanMoto's use of standardized UDS (`0x22`, `0x2E`, `0x11`, `0x19`, `0x14`) and KWP2000 diagnostic identifiers is a protected interoperability right under EU competition and right-to-repair frameworks.
3. No proprietary binary blob or trade-secret reverse engineering is required when exercising standardized RMI (Repair and Maintenance Information) interfaces.

### 2.2 BMW Motorrad AOS (Aftersales Online System)
BMW Group provides the **Aftersales Online System (AOS)** (`aos.bmwgroup.com`), which encompasses:
- **ISTA/D (Integrated Service Technical Application / Diagnostics)**: Official workshop diagnostic software.
- **ISTA/P (Programming)**: Calibration and vehicle order programming.
- **RMI Technical Documentation**: Official wiring schematics, pinout diagrams, connector pin designations, and Technical Service Bulletins (TSBs).
- Commercial subscriptions are available for independent repairers and tool developers on an hourly, daily, or annual basis.

### 2.3 EDIABAS SGBD / CABD Architecture & Motorcycle Applicability
BMW's EDIABAS runtime executes SGBD (Steuergeräte-Beschreibungs-Datei) scripts (`.PRG` files).
For BMW Motorrad, standard SGBD group files include:
- `MOTORRAD.GRP`: Master group dispatcher for bike platforms.
- `BMSK.PRG` / `BMSMP1.PRG` / `BMSX.PRG`: Engine management.
- `KOMBI24.PRG` / `KOMBI25.PRG` / `KOMBI46.PRG`: Instrument cluster diagnostics.
- `ZFE.PRG` / `ZFE_H.PRG` / `ZFE_B.PRG`: Central chassis electronics.
- `IABS.PRG` / `IABS2.PRG`: Anti-lock brake systems.

The parameters extracted from `libmotoscan-helper.so` (e.g. `KMBI_K25.C04`, `ZFE_C08`) are direct 1:1 reflections of the CABD table definitions compiled into these SGBD modules.

### 2.4 BMW Unified ECU Database (Licensing & Boundaries)
Automotive BMW databases (e.g. E-Sys PSDZData) do not include motorcycle ECUs. BMW Motorrad maintains an isolated branch of ECU definitions within ISTA/D. Diagnostic tool developers must not assume automotive F/G-series definitions apply to Motorrad modules.

### 2.5 BMW Motorrad CAN Bus Community Research
Extensive open-source community research (e.g. OpenBikeDiagnostic, ADVRider, K1600 forum CAN logging) has verified the physical and link layers:
- **Diagnostic Port**: 10-pin round connector (pre-EU4, ~2004–2016) and standard 16-pin OBD-II J1962 (EU4+, 2017+).
- **Physical Bus**: ISO 11898 CAN 2.0B at 500 kbps (CAN-High Pin 6, CAN-Low Pin 14).
- **Diagnostic Transport Protocol**: ISO 15765-2 (ISO-TP) with 11-bit CAN identifiers.
- **Diagnostic Application Protocol**: ISO 14229-1 (UDS).
- **KWP2000 Legacy**: ISO 14230-4 on K-Line (Pin 7) at 10,400 baud.

### 2.6 Competitor Architecture Comparison

| Diagnostic Capability | HEX Code GS-911 | WGSoft MotoScan | CrossScanMoto (Current) |
|---|---|---|---|
| **ECU Identification (UDS & KWP)** | Full OEM DIDs & KWP records | Full OEM DIDs & KWP records | **Full OEM DIDs & KWP records** |
| **Fault Memory (DTC Read/Clear)** | Supported across all platforms | Supported across all platforms | **Supported across all platforms** |
| **Realtime Live Sensor Data** | Realtime stream with scaling | 68 ECU groups with scaling tables | **68 ECU groups with scaling tables** |
| **Service Resets (Date & Distance)** | Verified KWP & UDS routines | Verified KWP & UDS routines | **Verified KWP & UDS routines** |
| **Actuator Component Testing** | Staged output testing | 45+ component tests | **Recovered Actuator Panel** |
| **ECU Coding Definition Source** | In-house compiled PRG/CABD | Embedded native tables in `.so` | **Recovered JSON catalog (48 variants)** |
| **ECU Coding Read & Decode** | Supported on selected ECUs | Supported via UDS 0x22 | **Supported via BmwCodingEngine** |
| **ECU Coding Write Guardrails** | Firmware-gated writes | Direct UDS 0x2E writes + reset | **Bench-safety locked until validated** |
| **Cryptographic State Backups** | Proprietary cloud backup | Local text file export | **SHA-256 tamper-evident JSON** |

---

## 3. Practical Coding Recovery in CrossScanMoto (Priority 3)

CrossScanMoto now includes:
1. **Catalog**: `assets/data/recovered_coding_definitions.json` (48 variants, 3,126 parameters, 8,990 options).
2. **Engine**: `BmwCodingEngine` (`lib/diagnostics/bmw_coding_engine.dart`):
   - Variant matching (e.g. `KOMBI_K25` + `0x04` -> `KMBI_K25_C04`).
   - Block readback via UDS `0x22` (`ReadDataByIdentifier`).
   - Bitfield parameter decoding against verified masks.
   - Tamper-evident backup generation with SHA-256 hash.
   - Safe parameter encoding preserving unmasked adjacent bits.
   - Fail-closed physical write guardrail: Writing is disabled (`allowPhysicalWrites = false`) until bench certification is completed.
3. **User Interface**: `RecoveredCodingPanel` (`lib/recovered_coding_panel.dart`) integrated into `ServiceCodingPage`:
   - Interactive variant selector.
   - Live parameter inspection with byte offsets, bitmasks, and option lists.
   - One-click "Read ECU Coding" and "Save Backup".
   - Clear hardware safety alert explaining that direct ECU writes are locked pending bench validation.
