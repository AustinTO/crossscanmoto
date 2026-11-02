# ECU table and request schema recovered from DEX code

Artifact: MotoScan 1.110 APK (`classes.dex`) paired with arm64 `libmotoscan-helper.so`. This note uses DEX bytecode disassembly and JNI declarations, not just matching strings. Focused excerpts are in `native-schema-disassembly.txt`; they can be recreated from the DEX with `dexdump -d` and locating the listed method offsets. All native functions remain opaque; evidence below is limited to the Java caller and its typed row parsers/joins.

## ECU-scoped table access

In `fl0.g(String)` (DEX method offset `0x217984`), the string argument is saved as the current ECU key. The loader calls the public wrapper `NativeLibMotoScan.n(String,String):String[]` with that same key and each literal table name below. **Wrapper correction, 2026-11-02:** the public wrapper delegates to private native `j(String,String):String[]`, exported as JNI `NativeLibMotoScan_j` at ELF RVA `0x6f6d84`. Private native `n(String):String[]` at `0x6f9574` takes a series name and is a different API. These names must not be equated by spelling alone. This mapping was rechecked with the supplied DEX and a single-class JADX 1.5.6 decompilation; see `docs/parity/RE-09-global-values.md` for targeted native probe evidence. Likewise public `p(String)` delegates to private native `k(String)` for global tables.

| ECU-keyed table | Use proven by caller |
|---|---|
| `PARAMS` | Parsed as `j21` rows; each row exposes a numeric primary key and byte-array field. |
| `PARAMS_RES` | Parsed as `k21` rows and attached to `PARAMS` rows when the result row's field `b` equals the parameter row's field `a` (numeric key equality). |
| `PARAMS_TAB` | Parsed as `ljw`-like rows and matched against a numeric field on `PARAMS_RES`; matching rows are attached to that result record. |
| `PARAMS_TAB_GLOBAL` | Also matched to result records; a matching row contains another string passed to native `p(String):String[]` to load a value list. |
| `ACTUATOR` | Parsed as actuator parents (`z6`). |
| `ACTUATORPOS` | Parsed as position/child rows (`x6`); child field `b` must equal actuator parent field `a`. |
| `ACTUATORCMD` | Parsed as command rows (`y6`); command field `a` must equal position field `a`. Commands are nested under their matched position and actuator. |
| `TROUBLECODES` | Parsed as `jj4`; the first two fields are integer-decoded and stored. |

`GENERAL_VALUES_UNITS` is queried through `NativeLibMotoScan.p(String)` rather than the two-key table API. Its rows are parsed as `nq4`; its first two semicolon fields are stored as integer and string. The loader filters records that contain `id` before adding them to the collection. The field-level role of that collection is not fully recoverable from this caller alone.

The DEX also calls the two-key `n(ecu, table)` API for all listed categories, establishing the ECU key/table relationship. It does **not** by itself establish a transport request or make raw commands safe to send.

## Parsed `PARAMS` row shape (bytecode-backed)

`j21.<init>(String)` (DEX offset `0x26cc1c`) splits on `;` and accesses at least eight positions. The loader passes `PARAMS` results to this constructor. The bytecode proves these fields/storage operations:

| Zero-based position | Operation shown in code |
|---:|---|
| 0 | `Integer.decode`, stored as `j21.a` (used as parent key for PARAMS_RES association). |
| 1 | Converted from a hex string into `byte[]`, stored as `j21.b`. |
| 2 | Stored unchanged as `j21.c` string. |
| 3 | `Integer.decode`, stored as `j21.d`. |
| 4 | `Integer.decode`, stored as `j21.e`. |
| 5 | `Integer.decode` is invoked, but the resulting integer is not stored in the visible constructor. |
| 6 | Compared with string `"1"`, stored as boolean `j21.f`. |
| 7 | Compared with `"1"`; the boolean result is not stored in the visible constructor. |
| 8+ | Not accessed in this constructor. |

This parser maps the recurring ten-field records into a parent object, but does not provide enough evidence to assign human meanings to fields 2–7 or to equate the byte array with a complete on-wire command. Do not build command emission from this mapping alone.

The `k21` constructor (DEX offset `0x26c788`) splits row strings on `;`, trims trailing empty tokens, and reads up to ten positions. The loader confirms `k21.b` is the foreign-key field matched against `j21.a`; a nested enum and other integer fields determine which tab/value metadata is attached. Full enum meanings remain opaque.

## Request-relevant conclusion

The most actionable recovered structure is a relational ECU-scoped metadata model:

`ECU key -> PARAMS -> PARAMS_RES -> PARAMS_TAB / PARAMS_TAB_GLOBAL -> native value-list table`

and, independently:

`ECU key -> ACTUATOR -> ACTUATORPOS -> ACTUATORCMD`.

This gives the app a defensible schema for representing discovered ECU operations and their associations, but exact diagnostic service IDs, byte encodings, read/write semantics, unlock preconditions and safe execution ordering are not established by these DEX joins. The `getCuDtc` JNI symbol is present in the native ELF, but no DEX declaration/call site was identified in the retained inventory. Avoid inferring its signature from the symbol name alone.

## Evidence boundaries

- The DEX loader's key is a `String` argument that it reuses as the first argument of `n(key, table)`; that establishes that a selected ECU identifier scopes these table lookups.
- `PARAMS_RES` parent-child joins and actuator/position/command joins are direct integer comparisons in bytecode.
- Native wrapper methods delegate to private native methods; string arrays and byte arrays are observed return/parsed types, not recovered native query semantics.
- No exact full app ECU inventory or complete field semantics are asserted here. See `native-data-findings.md` for the limits of printable-string extraction.
