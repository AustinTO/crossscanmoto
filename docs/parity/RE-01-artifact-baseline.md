# RE-01: original APK artifact baseline

These records fingerprint two local, publisher-signed APKs independently. The versions remain separate comparison baselines; evidence from one must not be attributed to the other. The APK binaries are not added to this repository.

## Pinned artifacts

See [`original-artifacts.json`](original-artifacts.json) for full hashes and expected entry-by-entry DEX/native hashes.

| Version | Local artifact path | Package / versionCode | APK SHA-256 | ABIs |
| --- | --- | --- | --- | --- |
| 1.110 | `MotoScan+for+BMW+Motorcycles_1.110_APKPure.apk` (repository root) | `de.wgsoft.motoscan` / `1110` | `bfc07ce264a0c35df9d63558f4fa64c4bd3dd845903d3e0417532250ea0e7e58` | arm64-v8a, armeabi-v7a, x86, x86_64 |
| 1.83 | `/tmp/crossmoto-motoscan-1.83.apk` (local-only) | `de.wgsoft.motoscan` / `183` | `f4b168234e2b3a042f35f3c0e8ee27a19e47bec0b32d01f1d6efa235ab39eacc` | arm64-v8a, armeabi-v7a, x86, x86_64 |

Both signatures verify with one signer: `CN=Wladimir Gurskij, O=WGSoft.de, L=Buende, ST=NRW, C=DE`; certificate SHA-256 `1921f55ca7de32d58a57e18dfbd27d3908cd48da1f2c377209769a6419a9d3bc`, SHA-1 `9ea0cc7e2ed44d91c744b37614985551d7ab91ba`. The 1.110 archive also reports unsigned META-INF metadata entries; `apksigner` reports these, so signature verification is not a claim that every such metadata entry is covered by the JAR signature. APK hash pins the exact inspected file.

## Verification and reproduction

From the repository root, with Android SDK Build Tools 36.0.0 installed:

```sh
python3 tool/verify_original_artifacts.py --version 1.110 --apk MotoScan+for+BMW+Motorcycles_1.110_APKPure.apk
python3 tool/verify_original_artifacts.py --version 1.83 --apk /tmp/crossmoto-motoscan-1.83.apk
```

The verifier is offline and read-only. A missing file or any hash/metadata/signature mismatch fails; a missing artifact blocks differential work requiring that version only. To independently reproduce the DEX and native-library fingerprints, extract a named entry without modifying the APK, then hash it:

```sh
unzip -p MotoScan+for+BMW+Motorcycles_1.110_APKPure.apk classes.dex > /tmp/motoscan-1.110-classes.dex
sha256sum /tmp/motoscan-1.110-classes.dex
/home/austin/Android/Sdk/build-tools/36.0.0/dexdump -d /tmp/motoscan-1.110-classes.dex > /tmp/motoscan-1.110-classes.disassembly.txt
unzip -p /tmp/crossmoto-motoscan-1.83.apk classes.dex > /tmp/motoscan-1.83-classes.dex
sha256sum /tmp/motoscan-1.83-classes.dex
/home/austin/Android/Sdk/build-tools/36.0.0/dexdump -d /tmp/motoscan-1.83-classes.dex > /tmp/motoscan-1.83-classes.disassembly.txt
```

Use the same `unzip -p APK ENTRY > /tmp/OUTPUT` and `sha256sum /tmp/OUTPUT` sequence for each `lib/<abi>/<name>.so` listed in the manifest. Keep extracted binaries and disassembly under a local temporary directory; do not commit them. Original acquisition/provenance notes: `assets/research/apk-findings.md` and `assets/research/historical-apk-acquisition.md`.
