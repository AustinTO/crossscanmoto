# Official version history and available analysis tooling

Reviewed 2026-10-30. The vendor's official [MotoScan changelog](https://www.motoscan.de/changelog/) spans beta releases back to 2015 and continues through v1.108 (dated 2026-02-10 on that page). Selected notes useful for historical protocol work:

- v0.26 (2016-01-20): instrument-cluster parameters became continuously requestable in real time.
- v0.34 (2016-05-02): OBDLink LX/MX support for K-Line and CAN is described.
- v0.44 (2016-12-09): F650GS/C1 ABS adds identification, DTC read/clear and live data.
- v0.47 (2017-02-16): extensive coding options and adapter requirements are called out.
- v0.49 (2017-04-23): UniCarScan adapter support and long-message checking are described.
- v0.55 (2018-03-02): ABS bleeding, actuator control and live-data coverage is listed across several ABS generations, with an explicit UCSI-2000 limitation for certain ABS-N actuator/bleed operations.
- v1.63 (2020-04-18): real-time data was overhauled, newer actuator diagnostics added across ECUs, and coding for newer models released.
- v1.88 (2023-06-01): BMS-MP KWP live data was integrated.
- v1.98 (2024-08-07): connection fixes for older ECUs including MA2.4 and FTE ABS.
- v1.108 (2026-02-10): newer-model coding, BMSK/BMSKP/BMSKP2 adaptation/reset/teaching, and coverage through model year 2026.

The official [version overview](https://www.motoscan.de/) says the app is distributed and sold through Google Play, identifies the Lite tier as free, and provides Google Play download links. I found no official standalone archive of earlier APK installers. Google Play's official listing describes the free app and current functionality, but does not expose a public historical APK download. So the vendor's public materials establish a free current Lite app, not a free vendor-hosted older APK. The [Google Play listing](https://play.google.com/store/apps/details?id=de.wgsoft.motoscan) is the supported acquisition route.

APKPure has a third-party version-index page, but it is not the vendor's distribution channel and its existence does not establish authorization or copyright status for redistributing old proprietary installers. I did not download any third-party, modified or unlocked package. A lawfully available older APK would need to come from the user's own legitimate installation/backup or direct vendor authorization; the official public pages reviewed here do not provide one. This is a distribution finding, not legal advice.

## Local analysis path

- `dexdump` exists in `/home/austin/Android/Sdk/build-tools/35.0.0/` and `36.0.0/`. The supplied DEX was successfully disassembled to `/tmp/motoscan-disassembly.txt`; this is usable bytecode evidence but not Java source decompilation.
- No JADX, Ghidra, CFR, Procyon, Apktool or Androguard installation/artifact was found under `/opt`, `/usr/share`, `/usr/local`, `/home/austin` caches/local tool areas in the checked paths. No config or system install was changed.
- `aarch64-linux-gnu-objdump` is available for native ELF disassembly; `readelf` and strings are also available.
- Consequently, the supported local path is DEX disassembly plus AArch64 disassembly, not source-level JADX/Ghidra decompilation. No standalone decompiler was available to complete Java-like recovery of the obfuscated KWP/service logic without adding a tool. The vendor changelog is useful for prioritizing KWP-era versions/features but does not supply the missing implementation details.
