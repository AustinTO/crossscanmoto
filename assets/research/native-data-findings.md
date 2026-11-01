# Native ECU data reconstruction notes

Artifact inspected: `libmotoscan-helper.so` arm64-v8a extracted as `/tmp/motoscan.so` (SHA-256 `bab0c173bb33c37262d07bbbbdc2c91213275d2a68e941d1b39fc3affd34fc71`). ELF is AArch64, Android API 23, stripped. Inventory is reproducible with `python3 tool/extract_motoscan_data.py /tmp/motoscan.so --output assets/research/native-data-inventory.json` (requires binutils `strings`). The tool only reads printable strings and never loads the ELF.

## Observed structures

- A `DATA` marker at file offset 1,387,168 precedes an embedded JSON-like block. The visible `easycoding` object identifies BMW series K50/K51, control unit `X_KOMBI3`, identifier `00004130`, and human-readable instrument-cluster startup-animation options. This is a concrete example of series-to-ECU metadata plus user-facing coding definitions.
- Semicolon-delimited string records recur throughout the ELF. The inventory counts 4,057 lines matching a two-digit initial field. Among the most conspicuous recurring families: `06` has 162 records (5 fields), `09` has 212 (6 fields), `10` has 1,311 (mostly 3 fields), and `12` has 1,886 (mostly 10 fields). These counts are printable-string occurrences, not unique database entities.
- A representative `12` row has shape `12;NAME;00003004;00000000;0001;0436;66;04;68;`. This exposes a symbolic name, several hex-looking values, and possible service/format attributes. Their precise field semantics and links to parent ECUs are not established.
- Visible content includes symbolic names such as oil-level readings, crash data, instrument settings and suspension parameters, alongside raw hex payloads and language-neutral tokens. Records appear to include coding/configuration and diagnostic/live-data material.

## Limits

The binary contains many semicolon-prefixed strings unrelated to these candidate record families (including numeric labels and diagnostic codes). The extraction script preserves offsets and field counts but intentionally does not infer semantics for opaque numbers, associate records with ECU/model parents, or emit the proprietary database as an app resource. Model/ECU enumeration is not complete or sufficiently proven from string evidence alone. Existing parity work should treat this as structural evidence only; runtime behavior and commands require independent control-flow and hardware validation.

## Pointer-table recovery follow-up (2026-10-31)

`tool/extract_native_pointer_tables.py` decodes AArch64 RELATIVE relocations for the static blocks copied by constructor 0x6fb7c0. Recovered exact header-led tables: 84 vehicle records, 7 series, 29 ECU groups (including original defaultprotocolid/defaultaddress), and 49 platform/group relationships. Results are in recovered-native/. Runtime representation in lib/diagnostics/recovered_catalog.dart preserves source field strings and does not equate database protocol IDs with Dart enum ordinals.

Further factory/vtable tracing establishes ECU key `cuMRABS` at 0x88e3d0 selects a table method at 0x892224. Its TROUBLECODES check at 0x8923e4 returns 27 pointers copied from array 0x985d00. `tool/extract_abs_dtc_table.py` recovers those actual code/description-ID pairs into recovered-native/cuMRABS-troublecodes.json. Description localization and exact vehicle applicability remain separate unresolved joins.

REA native-symbol Evidence: ev_6735ae03a87db8b1168c91d23e288756b9f4795a0a88bee5c012a587bee8dd8b. Detailed AArch64 disassembly above came from local GNU cross-objdump, not a REA decompiler. REA session still reports missing JADX provider; native provider readiness was checked without client configuration changes.

## Controlled offline table execution (2026-10-31)

With the installed AArch64 cross-compiler and qemu-aarch64, a custom ELF relocation loader invoked the original native factory/table functions without starting Android or contacting a motorcycle. This returned 234 nonempty tables containing 8,017 row occurrences for 55 observed ECU keys. Every retained row was independently checked as an exact byte string present in the original .so, and table stdout SHA-256/counts were rechecked. The 130 failed probes are recorded, not interpreted as missing tables. The custom loader omits ELF initializers and uses glibc shims, so these results establish returned table content, not original Android runtime equivalence.

Reproducible tools: tool/native/table_probe.c, extract_tables.py, build_parameter_catalog.py, build_definition_bundle.py. Data and validation manifest: recovered-native/runtime-tables/, runtime-tables-index.json, runtime-extraction-validation.json. A packaged 215 KB bundle is assets/data/recovered_ecu_definitions.json. A filtered catalog of 230 observed three-byte UDS 0x22 requests across 21 ECU definitions is assets/data/recovered_uds_parameters.json; live_data_page.dart now reads those requests through the configured UDS link and displays returned bytes instead of invented sensor waveforms. Scaling/localization remains unresolved and is not fabricated.
