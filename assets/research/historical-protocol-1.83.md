# MotoScan 1.83: historical KWP/service path recovered by decompilation

## Artifact verification

- Source listing: <https://apkpure.net/motoscan-for-bmw-motorcycles/de.wgsoft.motoscan/download/1.83>; download endpoint used: <https://d.apkpure.net/b/APK/de.wgsoft.motoscan?versionCode=183>.
- Local file: `historical-apks/motoscan-1.83.apk`, 14,626,933 bytes (13.95 MiB; archive lists 13.9 MB); SHA-256 `f4b168234e2b3a042f35f3c0e8ee27a19e47bec0b32d01f1d6efa235ab39eacc`.
- `aapt dump badging`: package `de.wgsoft.motoscan`, version 1.83, versionCode 183, min SDK 18.
- `apksigner verify --verbose --print-certs`: v1 and v2 signatures verify; one signer, `CN=Wladimir Gurskij, O=WGSoft.de, L=Buende, ST=NRW, C=DE`; certificate SHA-1 `9ea0cc7e2ed44d91c744b37614985551d7ab91ba`, SHA-256 `1921f55ca7de32d58a57e18dfbd27d3908cd48da1f2c377209769a6419a9d3bc`. These match the publisher certificate on the supplied 1.110 APK and the archive's reported 1.83 signer. Signature verification is cryptographic evidence that the downloaded APK payload is signed by that publisher key; it is not a vendor-hosted distribution attestation.
- Historical arm64 native engine extracted read-only to `/tmp/motoscan-1.83.so`: ELF AArch64, Android 21, stripped, 6,131,704 bytes, SHA-256 `c07e4802fb6708382a596db429790a6362bea614e3799122408a6b4f9c17a9b8`. The current supplied native library is larger and Android 23-targeted. Historical semicolon inventory: 3,262 record-like strings, including 1,586 family `12` and 949 family `10` rows; these are string occurrences, not unique entities.

## Decompiler used

Fetched JADX 1.5.6 CLI from its official release: <https://github.com/skylot/jadx/releases/download/v1.5.6/jadx-1.5.6.zip>. ZIP SHA-256 `545ea2be9c242511bc145755cf4bda2485ade42966e096f8b4d3da2a230e8974`; CLI reports version 1.5.6. Java 17.0.19 is installed. The archive and decompiled outputs remain under `/tmp` (not added to app runtime or checked into the research package). Set `JADX_CONFIG_DIR`, `JADX_CACHE_DIR`, and `JADX_TMP_DIR` to writable paths before use; otherwise JADX tries to create `/home/austin/.config/jadx` and fails under this read-only home configuration.

JADX produced Java output for the historical APK's 2,407 DEX classes. That pass reported five class-level decompilation errors, but the exact protocol methods below were emitted as readable Java. A current 1.110 decompilation was also attempted but its process ended before completion; current-version comparisons below use the retained DEX disassembly instead. The relevant historical source is under `/tmp/motoscan-1.83-jadx/sources/`.

## KWP connection and identity flow

`n2/a.java` contains the BMW motorcycle ECU initialization branches:

- Standard motorcycle KWP sends service-start byte `0x81`, with protocol `BMW_BIKE_KWP` and a 4,000 ms timeout. It treats response `0xC1` as positive. It also handles negative response `0x7F` with NRC `0x11`/`0x12` by probing `0x1A 0x80` and accepting a first response byte `0x5A`.
- FTE ABS initialization sends `0x81` under `BMW_BIKE_FTE_INIT`, changes the adapter protocol to `BMW_BIKE_FTE_WORK`, then sends the request again. A later explicit exit uses `0x82`.
- The sibling BMW KWA branch also sends `0x81`, under its own legacy protocol enum.
- UDS detection probes `0x1A 0x80`; its separate identification request is `0x22 0xF1 0x50` and checks response prefix `0x62 0xF1 0x50`.

This is static control-flow evidence of the app's request construction and response checks. ECU capability and adapter-specific runtime behavior remain untested here.

## KWP diagnostics and live data

`n2/d.java` is the ECU controller used by KWP and UDS descendants. It selects the init byte based on active protocol, sends diagnostic-session setup with a 3,000 ms timeout, and only proceeds once the response matches an accepted positive-response path.

- DTC read (`V()`): sends `18 02 FF FF` with a 3,000 ms timeout. The parser reads the count from response byte 1, then reads each trouble code from byte offsets `2 + 3*i` and `3 + 3*i`; each code is the two-byte value at that pair. This is enough to establish request and extraction layout, but not code descriptions/status semantics.
- DTC clear (`d()`): after diagnostic-session setup, sends `14 FF FF` with a 5,000 ms timeout and validates the positive response using request service versus response service offset `+0x40`. Calling this a clear-diagnostic-information operation is a protocol-standard inference from service `0x14`.
- Live parameter read (`U(parameterId)`): mutates a two-byte identifier in the request template `17 FF FF`, placing the parameter ID high byte then low byte, and sends it with a 3,000 ms timeout. Response data is passed through a parser; response byte 4 is separately decoded into additional parameter identifiers and labeled via the native localization helper.

The corresponding request templates are built in `k2/i.java`; its integer-array helper creates bytes from the listed unsigned values. The implementation supports app-side parameter selection and ECU metadata relationships documented in `native-schema-recovery.md`. It does not expose native database payloads as an app data resource.

## ELM framing and parity implementation

The historical ELM setup branch in `i3/g.c0` configures KWP with `ATPC`, `ATAL`, `ATSH81<address>F1`, `ATWM81<address>F13E`, `ATST50`, and `ATSP5`, in that order. Each command is accepted only when its response contains `OK`. KWP requests are written as contiguous uppercase hex. The response parser (`i3/a.b`, BMW_BIKE_KWP case) accepts each ELM line as a byte-count-prefixed frame with one trailing checksum byte: byte 0 is the payload length, payload begins at byte 1, and the frame must have `payloadLength + 2` bytes. It strips the count and checksum and returns the application payload. The separate `v3.d.q` helper removes spaces and commas and prepends a zero nibble to odd-length hex input.

`lib/diagnostics/kwp_client.dart` ports that KWP framing and setup. Its parser rejects a mismatched frame length rather than returning the all-zero array the old code produced on a mismatch. It accepts the historical odd-nibble normalization, but still rejects non-hex text; `?`/`NO DATA` become explicit errors instead of empty responses. KWP NRC 0x21 retry is capped at two retries, whereas the old implementation recursed without a bound; response-pending NRC 0x78 frames are drained from the same ELM prompt until a final frame appears, matching the old adapter's intended handling. It does not reassemble multi-frame KWP responses.

The current 1.110 DEX independently confirms the KWP init request and probe behavior: the `BMW_BIKE_KWP` ECU connect path sends `0x81`, uses the 4,000 ms timeout, and probes `0x1A 0x80` on the accepted negative-response branch; the per-operation path sends `0x81` with a 3,000 ms timeout and uses the same `0x1A 0x80` / `0x5A` readiness check. Its ELM protocol setup method `vq4.x` retains the KWP-related `ATPC`, `ATAL`, `ATSH81`, `ATWM81`, `ATST50`, and `ATSP5` strings. The 1.110 DEX uses an expanded protocol enum (including additional KWA variants). These findings confirm the shared request shapes but do not establish byte-for-byte identity of the complete 1.110 adapter setup branch or all service/catalog behavior.

The narrow runtime client is split into `BmwBikeKwpLink` (ELM setup, payload framing, start communication) and `KwpClient` (the recovered `0x18`, `0x14`, and `0x17` flows). Callers configure the link for an ECU address before constructing client operations; `KwpDtc.opaqueRecordByte` preserves the third response-record byte without assigning it an undocumented meaning. `readParameter` returns raw positive-response bytes for a separate catalog decoder. Tests use scripted ELM prompts and do not execute requests against a motorcycle.

## Boundaries

The APK is the normal versioned MotoScan package, publisher-signed and verified, not a patched or unlocked build. No licensing state was changed or bypassed, and no native code was loaded/executed. The decompiled sources are used only as local analysis evidence. The exact safe operating constraints, ECU-specific support matrix, session/security access requirements, and effects on a physical motorcycle still require runtime/hardware validation before an implementation emits these requests.
