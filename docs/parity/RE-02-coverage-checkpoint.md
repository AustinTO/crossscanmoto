# RE-02 independent source inventory checkpoint

## Scope and provenance

This checkpoint counts recovered metadata and recorded offline table-probe results from the MotoScan 1.110 arm64 native library (`libmotoscan-helper.so`, SHA-256 `bab0c173bb33c37262d07bbbbdc2c91213275d2a68e941d1b39fc3affd34fc71`; APK SHA-256 `bfc07ce264a0c35df9d63558f4fa64c4bd3dd845903d3e0417532250ea0e7e58`). Full input hashes and machine-readable evidence are in [RE-02-inventory-inputs.json](RE-02-inventory-inputs.json).

Pointer-table extraction yields **84 vehicle rows / IDs**, **7 series**, **29 ECU groups**, and **49 unique platform-to-group edges**. All vehicle series IDs and platform IDs have matching recovered rows. Group `defaultprotocolid` values are raw database IDs: `3` occurs 10 times and `8` occurs 19 times. No translation to Dart protocol enums is inferred.

The native caller/loader findings in [native-schema-recovery.md](../../assets/research/native-schema-recovery.md) establish table scope and exact integer field joins for parameter/result/tab and actuator/position/command rows. The Dart `groupsForVehicle` helper joins `vehicle.car_platformid -> platformEcuGroups.car_platformid -> ecu_groupsid -> ecuGroups.id`. No source-backed relation from those ECU group rows to observed runtime ECU key strings or factory handler IDs is established in these inputs; names/suffixes are not joined speculatively.

## Table action inventory

There are **68 candidate ECU key strings** and **10 table names** in `tool/native/extract_tables.py`, giving a 680-pair candidate grid. The retained `runtime-tables-index.json` contains **364 result entries**: **234 successful nonempty outputs / 8,017 rows** and **130 failures**. The script omits a candidate from the index when its subprocess returns successfully with empty stdout; the remaining **316 pairs are therefore labeled `UNRECORDED_EMPTY_CANDIDATE`**. They are not recorded observations of empty tables and do not establish data absence. Success payload counts and row hashes were checked against each corresponding runtime table JSON. The 130 recorded failures all have exit code 3 and `Invalid row count <process address>` errors; retain them as failed probes, not proof that a table is absent.

| Table | Candidate pairs | Recorded results | Nonempty outputs | Rows | Failures | Unrecorded candidates |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| ACTUATOR | 68 | 19 | 6 | 44 | 13 | 49 |
| ACTUATORCMD | 68 | 19 | 6 | 130 | 13 | 49 |
| ACTUATORPOS | 68 | 19 | 6 | 61 | 13 | 49 |
| FUNCTIONS | 68 | 65 | 52 | 389 | 13 | 3 |
| IDENTIFICATIONS | 68 | 67 | 54 | 207 | 13 | 1 |
| PARAMS | 68 | 34 | 21 | 230 | 13 | 34 |
| PARAMS_RES | 68 | 34 | 21 | 486 | 13 | 34 |
| PARAMS_TAB | 68 | 32 | 19 | 665 | 13 | 36 |
| PARAMS_TAB_GLOBAL | 68 | 13 | 0 | 0 | 13 | 55 |
| TROUBLECODES | 68 | 62 | 49 | 5,805 | 13 | 6 |
| **Total** | **680** | **364** | **234** | **8,017** | **130** | **316** |

The bundle contains 55 keys with one or more successful tables; the 13 other candidates are `cuX_ABS1K`, `cuX_BMSN`, `cuX_BMSZ`, `cuX_BSK_S2`, `cuX_BSK_S3`, `cuX_BSM_1`, `cuX_EDME`, `cuX_EDMEZ`, `cuX_LKD`, `cuX_MCCU`, `cuX_MIC`, `cuX_OBC_NV`, and `cuX_TCU01`. Five additional one-row `FUNCTIONS` files exist in `runtime-tables/` without a successful index entry (`cuMRDWA`, `cuMRABS`, `cuMRRBT`, `cuMRMA24`, `cuMRRDC`); they are flagged as supplemental unindexed files in the JSON and are not assigned to the 680-pair candidate grid without source provenance.

`FUNCTIONS` contains 389 indexed rows across 52 ECU keys. Token 0 is mapped by the `jl0.<init>` packed switch to a `kl0` category: raw code `8` is `CF_ADAPTIONS`, `12` is `CF_SERVICE` (`11` is `CF_SERVICE_FUNCTIONS`). This numeric mapping is distinct from the `kl0` enum ordinals. Token 1 is parsed as an integer; it is enabled only when equal to `1`, and `fl0.g` retains only those rows in its app list. Thus 243 rows pass the loader gate and 146 are filtered. Tokens 2–5 are parsed but not stored on the visible `jl0` object; token 6 is retained for localized category text. The five-field token1–5 patterns are: `1;0;0;0;0` = 237, `0;0;0;0;0` = 146, `1;1;0;0;0` = 4, `1;1;0;100;0` = 1, `1;0;1;0;0` = 1. Only the token1 inclusion behavior is assigned semantics here; other numeric fields remain preserved as raw values.

The cited DEX locations were checked against a fresh `dexdump` of the pinned `classes.dex`: `jl0.<init>` begins at `0x2198b4`, its switch is at `0x219902` with payload at `0x2199bc`, and `kl0.<clinit>` begins at `0x219704`. Decoding those 15 switch targets against the enum constants confirms raw code 8 → `CF_ADAPTIONS` and 12 → `CF_SERVICE`. The public `NativeLibMotoScan.n(String,String)` wrapper at `0x4e4118` invokes private `j(String,String)`; the matching native entry is in `native-table-j.asm` at ELF RVA `0x6f6d84` and calls the provider factory at `0x88e3d0`. `native-table-n.asm` at `0x6f9574` is a different private series-name method, not the ECU/table query path.

I cross-checked the generated graph in [handler-routing.json](../../assets/research/recovered-native/handler-routing.json) and the materialized [original capability matrix](../../assets/data/original_capability_matrix.json). The 680 key/table pairs appear once each with no missing or duplicate pairs; its status labels `returned_rows`, `legacy_probe_failed`, and `unrecorded` correspond respectively to the inventory labels `NONEMPTY_RECORDED`, `FAILED_RECORDED`, and `UNRECORDED_EMPTY_CANDIDATE`. All 389 FUNCTIONS direct edges resolve to their same-key source row and category map with no duplicate `(ECU key, raw row)` identity. The graph has 777 direct metadata/row edges, 398 category/query edges, zero missing direct edges, and no group-to-ECU-key or FUNCTIONS-to-execution-handler route. Its six unresolved edge classes explicitly retain those gaps. Exact native factory key comparisons are described as opaque metadata-provider branches, not diagnostic handler assignments.

## Limits

Counts refer to rows returned by the bounded native loader and its recorded probes, not tested ECU support, physical compatibility, app-runtime equivalence, or operation safety. The loader omitted ELF initializers and used glibc shims; the validation record explicitly limits claims to successfully returned tables. Empty table results, failed actions, and missing group/key joins remain separate evidence states. This checkpoint does not infer routes from text similarity.
