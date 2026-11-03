# Biketune 1.9.1 database investigation

## Scope and artifact identity

Read-only static inspection of the installed Android app and its matching local package; no motorcycle commands were issued. The connected device reported `app.biketune` version 1.9.1, version code 44. The installed base APK and the base APK in `Biketune_1.9.1_APKPure.xapk` matched SHA-256 `8ba30314faecaf3de401897f2a35fdeda2e1920cad5a7528a0ccfe28c645a218`.

The base APK contains `res/raw/assets_library_librarydb.enc`, 14,397,440 bytes, SHA-256 `85b25f7e4e9fe080add6c9b28e09faf249895d62cabd0e3db0c7f25e415622c0`. Its first bytes are not a SQLite header. The Hermes bundle `assets/index.android.bundle` has SHA-256 `76fe78c25679348520e12e3bff97c5acda0966b2f2f0e221c833ec239698deb9`.

## Reproducible inspection

The installed local Hermes compiler accepts the shipped bytecode as input:

```sh
unzip -p Biketune_1.9.1_APKPure.xapk app.biketune.apk > /tmp/biketune-base.apk
unzip -p /tmp/biketune-base.apk assets/index.android.bundle > /tmp/biketune.bundle
unzip -p /tmp/biketune-base.apk res/raw/assets_library_librarydb.enc > /tmp/biketune-library.enc
/home/austin/bleachers/expo-moq-webtransport/node_modules/hermes-compiler/hermesc/linux64-bin/hermesc -b -dump-bytecode /tmp/biketune.bundle > /tmp/biketune-disasm.txt
```

The resulting 84 MB disassembly has SHA-256 `260339fc1e976a3d061091763752056915ff76195b2e5e96cdf7944b32936630`. It is a local analysis artifact, not source code. The tool produces string-table entries and function-level bytecode; static references do not demonstrate that a path executed on this device.

## Findings

- The bundle contains `PRAGMA key = "x'`, `PRAGMA cipher_compatibility = 4`, and database-opening bytecode that calls `openDatabaseAsync` and `execAsync` for these statements. This is evidence of a keyed SQLCipher-compatible database path; the exact database schema and contents were not recovered.
- Functions named `fetchLibraryKey`, `fetchSupportUnlockedKey`, `resolveLibraryKey`, and `clearLibraryKeyCache` occur in the disassembly. The unlock flow includes `/library/unlock/request` and `/library/unlock/key` strings and references a wrapped key, local unwrapping, a 32-byte length check, and a cache. This indicates server-assisted key delivery, but static analysis alone does not prove which branch the installed instance used or whether its database has been opened.
- The bundle contains SQL queries referring to `coding_labels`, `coding_groups`, `coding_presets`, `coding_retrofits`, `service_functions`, `adaptations`, and ECU tables. These names show query targets, not the rows, completeness, ECU applicability, or executable write semantics.
- The device reports `ro.debuggable=0`; `run-as app.biketune` returns `package not debuggable`, direct access to the private app database is denied, and `su` was not found in the shell path. Ordinary ADB therefore did not provide access to the live private database or its key in this inspection.
- REA's Android package provider was unavailable because its caller-supplied JADX MCP JAR was not configured. The bytecode findings above were obtained with the local Hermes compiler instead.

## Open questions and boundaries

The encryption key, live database, complete schema, row counts, server policy, per-ECU write handlers, and vehicle applicability remain unverified. A database or label alone would not establish safe physical writes. A controlled test environment with authorized access to the app's own runtime and representative ECU/bench evidence is needed to resolve these questions. Do not treat the extracted encrypted file or static query strings as a complete recovered catalog.
