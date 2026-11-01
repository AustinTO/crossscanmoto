# Bundled versus server data investigation — 2026-10-31

Target: supplied MotoScan 1.110; identity in apk-findings.md. Static observations only, not a runtime network capture.

## Observed network call sites

Searching the complete retained DEX disassembly for java.net.URL.openConnection yields two call sites:

- e50, file offset 0x1d8948: CctTransportBackend, POST with datatransport/3.1.8 android User-Agent, gzip/application-json headers and X-Goog-Api-Key. This is Google telemetry transport, not evidence of a BMW diagnostic database endpoint. Retained class: network-Le50.txt.
- n00.w(String), method offset 0x1c4b60, call offset 0x1c4ba0: obtains the URL from ClassLoader.getResource, disables caching, returns its InputStream. This is classpath resource access; openConnection alone does not establish an HTTP download. Retained class: network-Ln00.txt.

DEX searches did not find okhttp/retrofit/DownloadManager/Firestore/Firebase classes in extracted string inventory. Literal URLs found are vendor informational pages, Play Store links, and dependency documentation. These bounded negative findings do not exclude reflective/dynamic networking or encoded endpoints.

## Bundled data observations

ECU-scoped PARAMS, PARAMS_RES, ACTUATOR and TROUBLECODES tables load through NativeLibMotoScan wrappers, as traced in native-schema-recovery.md. The native library embeds extensive semicolon-delimited diagnostic/coding data and an easycoding block. Its imported ELF symbols include file I/O but no socket/connect/getaddrinfo/recv/send/curl networking imports in the reviewed inventory. Direct syscalls/JNI/encoded or dynamic paths remain possible and were not exhaustively resolved.

Inference: available static evidence favors a packaged native diagnostic database. It does not currently support blaming missing service-reset details on a server dependency.

## Historical APK

Retried the 1.83 original-package archive endpoint documented in historical-apk-acquisition.md. Shell acquisition failed with curl error6: Could not resolve host d.apkpure.net. No historical bytes were obtained, so no historical signature/package/version comparison is claimed. No modified or unlocked APK was used.

Next concrete recovery work: native table extraction and protocol-specific el0.C implementations, their factory/ECU selection and dl0 reset-mode mapping. Real reset byte encodings are already recovered in service-reset-recovery.md; missing applicability/scaling/session details require control-flow evidence, not an invented backend.

## Resolved packaged-data extraction

Controlled offline execution under QEMU returned 234 nonempty native tables, 8,017 row occurrences and 55 observed ECU keys. Each retained row was checked against exact bytes in the supplied native library; see recovered-native/runtime-extraction-validation.json. This includes real PARAMS, PARAMS_RES, PARAMS_TAB, ACTUATOR, TROUBLECODES, FUNCTIONS and IDENTIFICATIONS content. Some empty/failed queries remain unresolved; no full database completeness claim is made. Packaged runtime bundle: assets/data/recovered_ecu_definitions.json. The original server-offload hypothesis is unnecessary for these recovered tables.
