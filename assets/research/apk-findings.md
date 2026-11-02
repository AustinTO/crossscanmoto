# MotoScan 1.110 artifact notes

Target: `MotoScan+for+BMW+Motorcycles_1.110_APKPure.apk`
SHA-256: `bfc07ce264a0c35df9d63558f4fa64c4bd3dd845903d3e0417532250ea0e7e58`
REA artifact evidence: `ev_eb14bd4d28e71f8707f9dd6bc984811363e3774591384a3fbe400edc6e8979f4` (complete APK central-directory inventory; 650 unique artifact nodes / 750 entry occurrences).

## Observed from the supplied shipped artifact

- APK contains `classes.dex` (6.78 MB) and `libmotoscan-helper.so` for arm64-v8a, armeabi-v7a, x86 and x86_64.
- The native library exports a large JNI surface under `de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan`, including a `getCuDtc` method and key-vault initialization. The helper embeds significant protocol and BMW diagnostic data.
- Protocol labels in DEX include BMW Motorrad KWP2000 (including FTE initialization/work and legacy ABS/MOT ECU variants), BMW Motorrad UDS, and BMW D-CAN.
- Operation categories include DTC read/clear, live data, service/service functions, adaptations, coding, configuration, identification, programming info, and actors/output tests.
- Embedded data includes diagnostic trouble-code descriptions, ECU identifiers and coding definitions. `easycoding` data includes BMW series K50/K51 and instrument cluster `X_KOMBI3` example definitions.
- Preferences include Bluetooth adapter name/address, Bluetooth connection type, communication type, Wi-Fi adapter IP/port, and BT/Wi-Fi settings categories.

## Inferences (not independently verified)

- The app likely communicates through a native transport abstraction supporting at least Bluetooth and Wi-Fi configured adapter paths. The exact chipset, BLE GATT UUIDs, classic SPP negotiation, USB profiles, adapter vendor compatibility and handshake remain unknown from string extraction alone.
- Native methods and a key vault indicate nontrivial protected logic. Reproducing secure service/coding operations from UI labels or database strings alone would be unsafe and unreliable.

## Gaps / limits

- REA Android package decompilation was unavailable in this session (JADX MCP provider missing); no decompiled call graph or source-level behavior is claimed.
- The app was not executed and no motorcycle/adapter traffic was captured. Static artifact strings do not establish working runtime behavior.
- A separate, verified 1.83 APK is now available at `/tmp/crossmoto-motoscan-1.83.apk`; its version identity, signer, and hashes are recorded in `docs/parity/original-artifacts.json`. See `docs/parity/RE-01-artifact-baseline.md` for reproducible local verification and extraction commands. The versions are separate baselines and were not merged.
- No adapter or motorcycle execution was performed during this artifact inspection. The Flutter implementation now has diagnostic request paths; their source/replay evidence is tracked separately under `docs/parity/`. This note does not establish physical compatibility.

## DEX disassembly follow-up

Android SDK dexdump recovered actual call sites: class `Lvq4;` invokes Bluetooth RFCOMM socket creation, connect, input/output streams, and Java TCP Socket connect/keepalive/timeouts. Adapter checks contain OBDLink LX, OBDLink MX and UniCarScan names. These establish static transport paths, not tested vendor compatibility. Focused disassembly is retained in transport-disassembly.txt. No connectGatt call was found in the bounded disassembly search.
