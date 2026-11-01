# Historical MotoScan APK acquisition attempt

Requested candidate: free MotoScan package `de.wgsoft.motoscan` version 1.83 / versionCode 183, APKPure archive listing dated Jan. 15, 2022. This predates the v1.90 changelog note that explicitly adds BMS-MP KWP live-data integration, making it a useful older comparison point. The APKPure version page identifies the artifact as a plain APK, 13.9 MB, Android 4.3+, with all four reported ABIs. Source page: <https://apkpure.net/motoscan-for-bmw-motorcycles/de.wgsoft.motoscan/download/1.83>. Its download endpoint is <https://d.apkpure.net/b/APK/de.wgsoft.motoscan?versionCode=183>.

## Integrity evidence and limits

- The APKPure version page reports signing-certificate SHA-1 `9ea0cc7e2ed44d91c744b37614985551d7ab91ba` for 1.83.
- Local `apksigner verify --print-certs` on the user-supplied 1.110 APK reports the same certificate SHA-1, with signer `CN=Wladimir Gurskij, O=WGSoft.de, L=Buende, ST=NRW, C=DE`; the local 1.110 APK SHA-256 is `bfc07ce264a0c35df9d63558f4fa64c4bd3dd845903d3e0417532250ea0e7e58`.
- This is consistent with the historical APK being signed by the same publisher, but cannot establish the actual archived file's integrity or contents without obtaining the APK. No actual historical APK was saved; SHA-256, APK signature validation, package/version verification, DEX comparison and analysis remain pending.

## Acquisition blocker

The web page's download link resolves to the APKPure endpoint above, but the web fetch tool returned `Cache miss` for the binary response. A local `curl -L --fail` attempt failed with `Could not resolve host: d.apkpure.net` (DNS/network unavailable in the shell). No network workaround, system configuration change or modified APK was used. The target directory was not retained because no APK bytes were received.

APKPure is a third-party archive, not the vendor distribution channel. The candidate is listed as the regular package/version and its reported signer matches the supplied publisher certificate; it is **not verified as unmodified until the file itself is acquired and checked**. Do not use the APKPure result alone to claim lawful redistribution or integrity.

## Retry outcome (2026-10-31)

A later authorized download succeeded from the same APKPure endpoint. The saved APK is `assets/research/historical-apks/motoscan-1.83.apk` (14,626,933 bytes), SHA-256 `f4b168234e2b3a042f35f3c0e8ee27a19e47bec0b32d01f1d6efa235ab39eacc`. `aapt` confirms `de.wgsoft.motoscan`, versionCode 183, versionName 1.83. `apksigner verify --verbose --print-certs` verifies v1 and v2 signatures and the single signer is WGSoft/Wladimir Gurskij, certificate SHA-1 `9ea0cc7e2ed44d91c744b37614985551d7ab91ba`, matching the supplied 1.110 publisher certificate. The APK is retained for research only; no license modification or bypass was performed. Historical protocol findings are recorded separately in `historical-protocol-1.83.md`.

The earlier cache miss and DNS failure describe the initial attempt only; they were resolved by the later network-capable execution context.
