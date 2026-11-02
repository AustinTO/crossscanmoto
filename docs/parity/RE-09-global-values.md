# RE-09: global units and enum-table recovery status

## Reproduced global table

`assets/research/recovered-native/units-runtime.txt` contains the complete
59-line `GENERAL_VALUES_UNITS` output. I reproduced it byte-for-byte on
2026-11-02 with the existing `tool/native/table_probe.c --global` path under
QEMU; stdout SHA-256 is
`ee1ff3d53ce1701de520b94ffb0e423eb5a6fd2fb893a8ab2ff19f2dd907bddc`.
The source rows begin `id;description;languageid`, `1;0/1;105476`,
`2;V;105477`, `7;°C;105482`, `8;km/h;105483`. `native-schema-recovery.md`
records the DEX parser behavior: it stores the first two row fields as integer
and string. This artifact is metadata only; it does not establish which units
apply to individual sensor results.

Capture provenance is recorded in
`assets/research/recovered-native/general-values-units.json`. The APK hash is
`bfc07ce264a0c35df9d63558f4fa64c4bd3dd845903d3e0417532250ea0e7e58`; extracted
arm64 library hash is
`bab0c173bb33c37262d07bbbbdc2c91213275d2a68e941d1b39fc3affd34fc71`.
The probe ran the local library through a custom ELF loader under QEMU with
CPU/address-space limits; no Android app process, network, or vehicle was used.

The DEX also gives a direct result association: `fl0.g` compares the parsed
GENERAL_VALUES_UNITS integer (`nq4.a`, raw field 0) to `PARAMS_RES` field 4
(`k21.e`) and stores `nq4.b` (raw field 1) on the result
(`0x217bf6-0x217c12`). Raw field 2 is parsed but not stored by `nq4`.
`tool/native/build_parameter_units_map.py` materializes those exact joins in
`assets/research/recovered-native/parameter-general-value-associations.json`:
486/486 captured result rows map to one of 58 raw display strings. The strings
include values such as `0/1`, `TEXT`, and `DATA`; the association is proven, but
not every string is necessarily a physical measurement unit.

For result rows with `PARAMS_TAB` children, `j21.b` uses the tab's token 3 as a
text id, obtains display text through `Les0.s(int)` (`0x26c6a2-0x26c6c6`), and
leaves the unit field blank. `Les0.s` calls `NativeLibMotoScan.I(int)` outside
its explicit dummy-text mode; the `I` wrapper calls native `t(int)`. The
`PARAMS_RES` token 14 is parsed to `k21.r` through `wr1.R(id, LNG_LIVE_DATA)`.
The enum switch sends `LNG_LIVE_DATA` to the same `Les0.s(int)` lookup path
(`wr1.R` at `0x2b295c`, `Ly72.d` ordinal 1, `ui4` switch table at `0x44be9c`).
When native text lookup does not resolve an id, the generated result retains
`label_id` and explicitly falls back to the parent parameter label with
`label_source: parameter_fallback`.

The generator writes `unit_id`, `unit`, raw `tabs` with `text_id` / resolved
`text`, and result `label_id` / resolved `label` per result record. The current
capture has 665 tab rows, 622 localized tab strings, and 43 references across
31 distinct ids whose native method-t response is the literal `unknown text`.
Ten result rows have 5 distinct result-label ids with the same placeholder.
The catalog preserves that literal with `text_source` / `label_source` set to
`native_placeholder`; it does not invent a description. The bounded per-id
reprobe using `tool/native/probe_re09_tab_texts.py` stores all seven raw native
method outputs and zero exit statuses for the 36 ids; see
`assets/research/recovered-native/re09-tab-text-reprobes.json`.

## Missing PARAMS_TAB_GLOBAL data

The authoritative replay now follows the original public JNI table path:
`NativeLibMotoScan.n(String,String)` calls private native `j(String,String)`
and maps a native `null` to an empty `String[]` (DEX `0x4e4118`). The bounded
probe calls private `j` at ELF RVA `0x6f6d84` with a minimal JNIEnv. Across 68
observed keys, `PARAMS` has 21 nonempty, 34 empty, 6 native-null, and 7 probe
fault results. The public wrapper normalizes those six nulls to empty arrays;
the seven faults remain unresolved and are not evidence of missing data. All
21 successful `PARAMS` controls match saved row counts and stdout hashes
exactly. For `PARAMS_TAB_GLOBAL`, 55 keys return empty arrays, 6 return null
(normalized to empty by the public wrapper), and 7 fault in the offline probe.
All 21 resolved ECUs return empty TAB_GLOBAL arrays; no nonempty TAB_GLOBAL
rows were returned. Results and controls are preserved in
`assets/research/recovered-native/re09-jni-table-probes.json`.

The earlier `re09-tab-global-probes.json` used the object/vtable probe and is
superseded: its invalid-row-count output is not an absence signal. The existing
`--global PARAMS_TAB_GLOBAL` query also returns zero rows; that one-argument
lookup is not a substitute for the ECU-keyed method. The DEX shows that
`fl0.g` calls `n(ecu, "PARAMS_TAB_GLOBAL")`, joins its rows to result keys, and
then calls `p(row.y)` for a named value list. No names are available from the
retained tables, and localized text extraction does not supply them.

Next recovery step: validate the ECU-scoped native query's returned-row ABI for
these empty/error cases against a known successful key and DEX call path, then
capture only successful raw rows with the same offline probe. Once row names
are recovered, query each value list through `p(String)` and preserve its raw
output. Do not infer enum labels from units or from adjacent DEX fields.
