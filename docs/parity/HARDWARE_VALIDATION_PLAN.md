# BMW Motorrad Minimum Hardware Validation Plan

## 1. Objectives & Scope

This document defines the physical hardware validation plan required to certify ECU coding writes, service resets, and bidirectional actuator operations for CrossScanMoto before enabling live write execution in customer production builds.

Until this plan is executed on physical bench hardware, **all ECU coding writes remain strictly disabled (`allowPhysicalWrites = false`)** under CrossScanMoto's fail-closed safety policy.

---

## 2. Minimum Representative Donor ECUs

To achieve maximum diagnostic validation coverage with the smallest physical bench setup, three representative BMW Motorrad electronic control units (ECUs) are selected:

### 2.1 ECU 1: KOMBI (K25 / K46) Instrument Cluster (Top Priority)
- **Applicable Platforms**: K25 (R1200GS / Adventure 2004–2012), K46 (S1000RR 2010–2018), K71 (F800R/GT).
- **Representative Part Numbers**: `62118558667`, `62118522616`, `62117727100` (Bosch / Continental).
- **Diagnostic Protocol**: ISO 14229-1 (UDS) over ISO 15765-2 (CAN 500 kbps, 11-bit IDs).
- **Diagnostic Address**: `0x60` (Tx `0x6F2`, Rx `0x612`).
- **Target DIDs**:
  - `0x3005` (`Country_Code`, 3 bytes): `CLOCK_MODE`, `ODO_UNIT`, `TEMP_UNIT`, `CONSUMPTION_UNIT`, `PRESSURE_UNIT`.
  - `0x300A` (`Equipment`, 5 bytes): `BC` (Trip Computer), `SITZHEIZUNG`, `DWA`, `RDC`, `ASC`.
  - `0x300B` (`Display`, 13 bytes): `DISPLAY_NO_RADIO`, `ZTDC`, `ZDDC`.
  - `0x300F` (`Service_Anzeige`, 9 bytes): Service date & distance display intervals.
- **Why Selected**:
  1. Low risk: In the event of an invalid write, instrument clusters reject out-of-range payloads with UDS NRC `0x31` (`RequestOutOfRange`) or `0x22` (`ConditionsNotCorrect`) without immobilizing the vehicle.
  2. Immediate visual verification: Changes (e.g. 12h vs 24h clock, km vs miles) are directly visible on the cluster LCD/TFT without auxiliary test equipment.
  3. Covers both ECU coding reads/writes and service interval resets.

### 2.2 ECU 2: BMSX / BMSMP1 Engine Management Unit (DME)
- **Applicable Platforms**: K46 (S1000RR), K50 (R1200GS LC), K51 (R1200GS Adv LC).
- **Representative Part Numbers**: Bosch ME17.2 / ME17.2.4 (`13618522449`, `13618542055`).
- **Diagnostic Protocol**: ISO 14229-1 (UDS) over CAN 500 kbps.
- **Diagnostic Address**: `0x12` / `0x10` (Tx `0x6F0`, Rx `0x610`).
- **Target Operations**:
  - Live sensor data polling (RPM, coolant temp, throttle position, ambient pressure).
  - Actuator testing (fuel pump relay, radiator fan relay, exhaust flap servo).
  - Adaptation resets (throttle twistgrip, lambda sensors).

### 2.3 ECU 3: ZFE (Basic / High) Chassis Electronics Module
- **Applicable Platforms**: K25 (R1200GS), K26 (R1200RT), K27 (R1200R).
- **Representative Part Numbers**: Lear / Delphi ZFE High (`61357717462`, `61357705183`).
- **Diagnostic Protocol**: ISO 14229-1 (UDS) over CAN 500 kbps.
- **Diagnostic Address**: `0x00` (Tx `0x6F4`, Rx `0x614`).
- **Target DIDs**:
  - `0x300A` / `0x300B` / `0x300C`: `LED_KL54_OUTPUT` (LED tail light), `LED_FRONT_TURNLAMPS` (LED indicators retrofit), `TIME_INDIC_LIMIT`, `DISTANCE_INDIC_LIMIT`.
- **Why Selected**:
  - Validates chassis retrofit coding (e.g. enabling LED turn signals without ballast resistors).

---

## 3. Bench Test Rig Architecture & Wiring

A minimal bench rig connects a regulated DC power supply and an OBD-II adapter to the donor ECU.

### 3.1 Wiring Schematic

```
[12V 5A Power Supply]
  ├── +12V DC ────────┬────────────────────────────► OBD-II Socket Pin 16 (Battery +)
  │                   ├────────────────────────────► Donor ECU Pin (KL30 / Battery +)
  │                   └─────[ Toggle Switch ]──────► Donor ECU Pin (KL15 / Ignition +)
  │
  └── GND (0V) ───────┬────────────────────────────► OBD-II Socket Pin 4 & 5 (Chassis GND)
                      └────────────────────────────► Donor ECU Pin (KL31 / Ground)

[CAN Bus Wiring]
  Donor ECU CAN-High ─┬────────────────────────────► OBD-II Socket Pin 6 (CAN-H)
                      │
                   [120Ω 1/4W Resistor]
                      │
  Donor ECU CAN-Low ──┴────────────────────────────► OBD-II Socket Pin 14 (CAN-L)

[OBD-II Diagnostic Adapter]
  Plugged into OBD-II Socket (UniCarScan UCSI-2100, OBDLink LX, or vLinker MC+)
```

### 3.2 Bill of Materials (BOM)
1. **Donor KOMBI Cluster**: K25 or K46 instrument cluster (~$80–$150 on eBay / motorcycle salvage).
2. **Bench Power Supply**: 12V–14V, 3A–5A regulated DC power supply ($30–$50).
3. **OBD-II 16-Pin Female Breakout Socket**: J1962 female connector with wire pigtails ($8).
4. **120-Ohm Termination Resistor**: 1/4W metal film resistor placed across CAN-H and CAN-L ($1).
5. **Connecting Leads**: Dupont female jumper leads for ECU connector pins.
6. **Diagnostic Adapter**: UniCarScan UCSI-2100 (recommended) or OBDLink LX.

---

## 4. Staged Validation Protocol

Validation must proceed in three strictly sequential stages. Each stage requires full documentation and CAN bus log captures before advancing.

### Stage 1: Read-Only Verification (Zero Risk)
1. Power up bench rig (12V KL30 and KL15 active).
2. Connect CrossScanMoto to adapter via Bluetooth/Wi-Fi.
3. Verify ECU Auto-Scan detects donor ECU address (`0x60` for KOMBI) without collisions.
4. Read identification DIDs:
   - `0xF187` (BMW Spare Part Number)
   - `0xF190` (VIN)
   - `0xF189` (Software Version)
   - Byte `0x02` of identification record (Coding Index, e.g. `0x04`).
5. In CrossScanMoto **ECU Coding & Backup** tab:
   - Verify variant matches `KMBI_K25_C04`.
   - Tap **Read ECU Coding**.
   - Verify all 4 blocks (`0x3005`, `0x300A`, `0x300B`, `0x300F`) return positive responses (`0x62`).
   - Verify decoded parameters (e.g. `CLOCK_MODE = 24h`, `ODO_UNIT = km`) match the physical LCD display.
   - Confirm zero Negative Response Codes (NRCs).

### Stage 2: Cryptographic Backup Verification
1. Tap **Save Backup** in CrossScanMoto.
2. Verify:
   - Backup record is created with timestamp, VIN, model, and variant key.
   - SHA-256 digest is generated from the concatenated block bytes.
   - JSON backup exports cleanly and can be re-imported with identical hash.

### Stage 3: Controlled Bench Write & Readback Verification
> **Prerequisite**: Stage 1 and Stage 2 must be 100% verified. Test must be executed on a donor bench cluster, NEVER on an assembled customer motorcycle.

1. Select non-destructive parameter: `CLOCK_MODE` (`24h` <-> `12h`) in block `0x3005`.
2. Construct modified payload:
   - Original block byte 1: `0x01` (24h).
   - Target block byte 1: `0x00` (12h).
3. Transmit UDS `0x2E 30 05 00 00 00` (`WriteDataByIdentifier`).
4. Verify positive response `0x6E 30 05`.
5. Transmit UDS `0x11 01` (`ECUReset, HardReset`).
6. Verify positive response `0x51 01`.
7. Wait 3,000 ms reboot delay.
8. Transmit UDS `0x22 30 05` (`ReadDataByIdentifier`).
9. Verify readback payload byte 1 is `0x00` (12h).
10. Observe physical cluster LCD: Clock display format should toggle from `14:00` to `2:00 PM`.
11. Restore original backup (`0x2E 30 05 00 01 00`) and verify restoration.

---

## 5. Certification Sign-Off Criteria

Before `allowPhysicalWrites` is permanently enabled in production:
1. Stage 1, 2, and 3 pass with 100% repeatability (minimum 10 successive write/restore cycles without communication timeout or failure).
2. Complete CAN bus capture logs (`.candump` or `.pcap`) are archived in `assets/research/validation-logs/`.
3. Readback byte-for-byte identity is mathematically proven.
4. Production release notes explicitly list bench-certified ECU families and keep unverified modules locked.
