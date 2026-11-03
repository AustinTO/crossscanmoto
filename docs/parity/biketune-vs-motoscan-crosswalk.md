# Biketune 1.9.1 vs MotoScan 1.110 Diagnostics Crosswalk

> Provenance-tracked identity mapping between recovered Biketune SQLite catalog, MotoScan native tables, and CrossScan internal identifiers.

## Identifier Namespaces

| System | Namespace | Example | Description |
|---|---|---|---|
| Biketune Source | `source:biketune:1.9.1:bike:<ebr>` | `source:biketune:1.9.1:bike:K50` | Primary bike model identifier in Biketune schema |
| Biketune Variant | `source:biketune:1.9.1:variant:<ebr>:<code_or_index>` | `source:biketune:1.9.1:variant:K50:0A01` | Specific variant/typenschlüssel code |
| Biketune ECU | `source:biketune:1.9.1:ecu:<ecu_name>` | `source:biketune:1.9.1:ecu:X_BMS-O-BMS` | ECU identifier from Biketune `ecus` table |
| MotoScan Platform | `source:motoscan:car_platformid:<id>` | `source:motoscan:car_platformid:2` | Physical diagnostic platform / protocol routing ID |
| MotoScan Group | `source:motoscan:group:<modulegroup>` | `source:motoscan:group:G_MRMOT` | Native vehicle-to-modulegroup mapping entry |
| MotoScan Candidate ECU | `source:motoscan:candidate:<key>` | `source:motoscan:candidate:cuX_BMSO1` | Recovered candidate table identification key |
| CrossScan Internal Model | `crossscan:vehicle:<chassis>:<variant>` | `crossscan:vehicle:K50:r1250gs_shiftcam` | Workshop profile motorcycle identity |
| CrossScan Routing Key | `crossscan:ecu:<protocol>_0x<hex>` | `crossscan:ecu:uds_0x12` | Collision-free bus routing address |

## Model & Variant Crosswalk

| Biketune EBR | Marketed Name | Series | Years | Protocol | MotoScan Series | MotoScan Platform ID | Ambiguity / Collision Handling |
|---|---|---|---|---|---|---|---|
| `259` | R 850 GS, R 1100 GS, R 850 RT, R 1100 RT, R 850 RS, R 1100 RS | K001 | 1992–2006 | bmw-legacy-cluster | `259` | `7` | Direct mapping |
| `259C` | R 850 C, R 1200 C, R 1200 C Montauk, R 1200 C Independent | K001 | 1996–2004 | bmw-legacy-cluster | `259C` | `7` | Direct mapping |
| `259R` | R 850 R, R 1100 R | K001 | 1993–2002 | bmw-legacy-cluster | `259R` | `7` | Direct mapping |
| `C1` | C1 | K001 | 1999–2003 | bmw-legacy-cluster | `C01` | `3` | Direct mapping |
| `E169` | F 650, F 650 ST | K001 | 1993–2003 | bmw-legacy-cluster | `E169` | `7` | Direct mapping |
| `H61` | TR650 Strada, TR650 Terra | K001 | 2013–2013 | bmw-legacy-cluster | `H61` | `4` | Direct mapping |
| `H91` | Nuda 900, Nuda 900 R | K001 | 2012–2013 | bmw-legacy-cluster | `Unmatched` | `—` | Catalog-only prototype / generic |
| `K02` | G 310 GS | KS01 | 2016–present | bmw-bk-cluster | `Unmatched` | `—` | Catalog-only prototype / generic |
| `K03` | G 310 R | KS01 | 2016–present | bmw-bk-cluster | `Unmatched` | `—` | Catalog-only prototype / generic |
| `K06` | CE 02 | XS01 | 2022–present | bmw-bk-cluster | `Unmatched` | `—` | Catalog-only prototype / generic |
| `K07` | CE 04 | KE01 | 2020–present | bmw-bk-cluster | `Unmatched` | `—` | CE 04 electric scooter; explicit platform routing |
| `K08` | C 400 GT | KS01 | 2018–present | bmw-bk-cluster | `Unmatched` | `—` | Catalog-only prototype / generic |
| `K09` | C 400 X | KS01 | 2018–present | bmw-bk-cluster | `Unmatched` | `—` | Catalog-only prototype / generic |
| `K14` | F 650 CS | K001 | 2000–2005 | bmw-legacy-cluster | `K14` | `3` | Direct mapping |
| `K15` | G 650 Xchallenge, G 650 Xmoto, G 650 Xcountry | K001 | 2006–2009 | bmw-legacy-cluster | `K15` | `3` | Direct mapping |
| `K16` | G 450 X | K001 | 2007–2010 | bmw-legacy-cluster | `K16` | `3` | Direct mapping |
| `K17` | C evolution | KE01 | 2013–2020 | bmw-bk-cluster | `Unmatched` | `—` | Catalog-only prototype / generic |
| `K18` | C 600 Sport | K001 | 2011–2020 | bmw-bk-cluster | `K18` | `1` | Direct mapping |
| `K19` | C 650 GT | K001 | 2011–2020 | bmw-bk-cluster | `K19` | `1` | Direct mapping |
| `K21` | R nineT | K001 | 2013–2023 | bmw-bk-cluster | `Unmatched` | `—` | Dual-platform: KWP (pid=1, BMSK) vs UDS (pid=2, XBMSMP1) |
| `K22` | R nineT Pure | K001 | 2015–2023 | bmw-bk-cluster | `Unmatched` | `—` | Catalog-only prototype / generic |
| `K23` | R nineT Scrambler | K001 | 2015–2023 | bmw-bk-cluster | `Unmatched` | `—` | Catalog-only prototype / generic |
| `K25` | R 1200 GS, R 1200 GS Adventure, R 1200 GS HP | K001 | 2002–2013 | bmw-kwp-kline | `K25` | `1` | Direct mapping |
| `K26` | R 900 RT, R 1200 RT | K001 | 2003–2014 | bmw-kwp-kline | `K26` | `1` | Direct mapping |
| `K27` | R 1200 R | K001 | 2005–2014 | bmw-kwp-kline | `K27` | `1` | Direct mapping |
| `K28` | R 1200 ST | K001 | 2003–2007 | bmw-kwp-kline | `K28` | `1` | Direct mapping |
| `K29` | R 1200 S, HP2 Sport | K001 | 2004–2010 | bmw-kwp-kline | `K29` | `1` | Direct mapping |
| `K30` | R 1200 CL | K001 | 2001–2004 | bmw-legacy-cluster | `K30` | `7` | Direct mapping |
| `K32` | R nineT Racer | K001 | 2015–2019 | bmw-bk-cluster | `Unmatched` | `—` | Catalog-only prototype / generic |
| `K33` | R nineT Urban G/S | K001 | 2016–2023 | bmw-bk-cluster | `Unmatched` | `—` | Catalog-only prototype / generic |
| `K34` | R 18, R 18 Classic | K001 | 2019–present | bmw-bk-cluster | `Unmatched` | `—` | Catalog-only prototype / generic |
| `K35` | R 18 B, R 18 Transcontinental | K001 | 2020–present | bmw-bk-cluster | `Unmatched` | `—` | Catalog-only prototype / generic |
| `K40` | K 1200 S, K 1300 S | K001 | 2003–2015 | bmw-bk-cluster | `K40` | `1` | Direct mapping |
| `K41` | K 1200 GT, K 1200 RS | K001 | 2000–2005 | bmw-legacy-cluster | `K41` | `7` | Direct mapping |
| `K42` | HP4 | K001 | 2011–2014 | bmw-bk-cluster | `Unmatched` | `—` | Catalog-only prototype / generic |
| `K43` | K 1200 R, K 1300 R | K001 | 2004–2015 | bmw-bk-cluster | `K43` | `1` | Direct mapping |
| `K44` | K 1200 GT, K 1300 GT | K001 | 2004–2010 | bmw-bk-cluster | `K44` | `1` | Direct mapping |
| `K46` | S 1000 RR, S 1000 RR M | K001 | 2008–2018 | bmw-bk-cluster | `K46` | `1` | Split generation: 2010–2012 BMSKP vs 2013+ BMSX |
| `K46MU2` | S 1000 RR | K001 | 2010–2012 | UDS | `K46` | `1` | Sub-variant mapped to base MotoScan series K46 |
| `K46MU3` | S 1000 RR | K001 | 2010–2012 | UDS | `K46` | `1` | Sub-variant mapped to base MotoScan series K46 |
| `K47` | S 1000 R | K001 | 2013–2020 | bmw-bk-cluster | `Unmatched` | `—` | Catalog-only prototype / generic |
| `K48` | K 1600 GT, K 1600 GTL | K001 | 2010–present | bmw-bk-cluster | `K48` | `2` | Sub-variant mapped to base MotoScan series K48 |
| `K4811` | K 1600 GT, K 1600 GTL | K001 | 2011–present | UDS | `K48` | `2` | Sub-variant mapped to base MotoScan series K48 |
| `K4812` | K 1600 GT, K 1600 GTL | K001 | 2011–present | UDS | `K48` | `2` | Sub-variant mapped to base MotoScan series K48 |
| `K49` | S 1000 XR | K001 | 2014–2019 | bmw-bk-cluster | `Unmatched` | `—` | Catalog-only prototype / generic |
| `K50` | R 1200 GS, R 1250 GS | K001 | 2011–2023 | bmw-bk-cluster | `K50` | `2` | Direct mapping |
| `K51` | R 1200 GS Adventure, R 1250 GS Adventure | K001 | 2012–2024 | bmw-bk-cluster | `K51` | `2` | Direct mapping |
| `K52` | R 1200 RT, R 1250 RT | K001 | 2013–2024 | bmw-bk-cluster | `K52` | `2` | Direct mapping |
| `K53` | R 1200 R, R 1250 R | K001 | 2013–2024 | bmw-bk-cluster | `K53` | `2` | Direct mapping |
| `K54` | R 1200 RS, R 1250 RS | K001 | 2014–2024 | bmw-bk-cluster | `K54` | `2` | Direct mapping |
| `K589` | K 1100 RS, K 1100 LT, K 1200 RS, K 1200 LT | K001 | 1989–2008 | bmw-legacy-cluster | `K589` | `7` | Direct mapping |
| `K60` | HP4 Race | KS01 | 2017–2018 | bmw-bk-cluster | `Unmatched` | `—` | Catalog-only prototype / generic |
| `K61` | K 1600 B, K 1600 Grand America | K001 | 2017–present | bmw-bk-cluster | `Unmatched` | `—` | Catalog-only prototype / generic |
| `K63` | S 1000 R | K001 | 2020–present | bmw-bk-cluster | `Unmatched` | `—` | Catalog-only prototype / generic |
| `K66` | M 1000 RR | K001 | 2020–present | bmw-bk-cluster | `Unmatched` | `—` | Catalog-only prototype / generic |
| `K67` | S 1000 RR | K001 | 2018–present | bmw-bk-cluster | `Unmatched` | `—` | Catalog-only prototype / generic |
| `K69` | S 1000 XR | K001 | 2018–present | bmw-bk-cluster | `Unmatched` | `—` | Catalog-only prototype / generic |
| `K70` | F 700 GS | K001 | 2011–2017 | bmw-kwp-kline | `K70` | `1` | Direct mapping |
| `K71` | F 800 S, F 800 ST, F 800 GT | K001 | 2004–2019 | bmw-kwp-kline | `K71` | `1` | Direct mapping |
| `K72` | F 650 GS, F 800 GS | K001 | 2006–2018 | bmw-kwp-kline | `K72` | `1` | Direct mapping |
| `K73` | F 800 R | K001 | 2005–2019 | bmw-kwp-kline | `K73` | `1` | Direct mapping |
| `K75` | F 800 GS Adventure | K001 | 2012–2017 | bmw-bk-cluster | `K75` | `1` | Direct mapping |
| `K80` | F 750 GS, F 800 GS | K001 | 2016–present | bmw-bk-cluster | `Unmatched` | `—` | Catalog-only prototype / generic |
| `K81` | F 850 GS, F 900 GS | K001 | 2016–present | bmw-bk-cluster | `Unmatched` | `—` | Catalog-only prototype / generic |
| `K82` | F 850 GS Adventure, F 900 GS Adventure | K001 | 2017–present | bmw-bk-cluster | `Unmatched` | `—` | Catalog-only prototype / generic |
| `K83` | F 900 R | K001 | 2018–present | bmw-bk-cluster | `Unmatched` | `—` | Catalog-only prototype / generic |
| `K84` | F 900 XR | K001 | 2018–present | bmw-bk-cluster | `Unmatched` | `—` | Catalog-only prototype / generic |
| `KA1` | R 1300 GS | K001 | 2022–present | bmw-bk-cluster | `Unmatched` | `—` | Catalog-only prototype / generic |
| `KA2` | R 1300 GS Adventure | K001 | 2023–present | bmw-bk-cluster | `Unmatched` | `—` | Catalog-only prototype / generic |
| `KA3` | R 1300 RT | K001 | 2025–present | bmw-bk-cluster | `Unmatched` | `—` | Catalog-only prototype / generic |
| `KD1` | Unknown | XS01 | —–present | UDS | `Unmatched` | `—` | Catalog-only prototype / generic |
| `KD2` | Unknown | XS01 | —–present | UDS | `Unmatched` | `—` | Catalog-only prototype / generic |
| `KD3` | Unknown | XS01 | —–present | UDS | `Unmatched` | `—` | Catalog-only prototype / generic |
| `KM3` | M 1000 R | K001 | 2021–present | bmw-bk-cluster | `Unmatched` | `—` | Catalog-only prototype / generic |
| `KM9` | S 1000 XR | K001 | 2023–present | bmw-bk-cluster | `Unmatched` | `—` | Catalog-only prototype / generic |
| `KR1` | R 12 nineT | K001 | 2022–present | bmw-bk-cluster | `Unmatched` | `—` | Catalog-only prototype / generic |
| `KR2` | R 12 G/S | K001 | 2024–present | bmw-bk-cluster | `Unmatched` | `—` | Catalog-only prototype / generic |
| `KR3` | R 12 | K001 | 2022–present | bmw-bk-cluster | `Unmatched` | `—` | Catalog-only prototype / generic |
| `OBD2` | Generic OBD-II vehicle | K001 | —–present | obd2 | `Unmatched` | `—` | Catalog-only prototype / generic |
| `R13` | F 650 GS, F 650 GS Dakar, G 650 GS, G 650 GS Sertão | K001 | 1999–2015 | bmw-legacy-cluster | `R13` | `3` | Direct mapping |
| `R21` | R 1150 GS, R 1150 GS Adventure | K001 | 1998–2005 | bmw-legacy-cluster | `R21` | `7` | Direct mapping |
| `R22` | R 850 RT, R 1150 RT, R 1150 RS | K001 | 2000–2006 | bmw-legacy-cluster | `R22` | `7` | Direct mapping |
| `R28` | R 850 R, R 1150 R, Rockster | K001 | 1999–2007 | bmw-legacy-cluster | `R28` | `7` | Direct mapping |

## Coding Domain Incompatibility

- **MotoScan Native Coding:** Structured around UDS DID blocks (e.g. `0x3005`) with bitmasks, integer offsets, and enumerated values (`KMBI_K25_C04`). Communicates directly via standard UDS `0x22` and `0x2E`.
- **Biketune CAFD Coding:** Structured around BMW E-Sys CAFD containers (`cafd_root`, `cafd_version`, `register`, `bit_start`, `bit_end`). Commits require multi-step Hermes procedures (`writeCodingPage`, `commitCodingTransaction`, `commitCps`).
- **Safety Guardrail:** CAFD fields are **NEVER** coerced into DID offsets. Mismatched firmware/CAFD versions prevent coding readback and physical writes.

