# RE-02 routing evidence and boundaries

## Source identity and direct joins

The source is MotoScan 1.110: APK SHA-256
`bfc07ce264a0c35df9d63558f4fa64c4bd3dd845903d3e0417532250ea0e7e58`,
`classes.dex` SHA-256
`869025551e5339811c300f2ae5ec92563c7e6b228d9498b8e835e2ac79283832`, and
arm64 `libmotoscan-helper.so` SHA-256
`bab0c173bb33c37262d07bbbbdc2c91213275d2a68e941d1b39fc3affd34fc71`.

The recovered tables give direct relationships for 84 vehicle records, 7
series, 49 platform-to-ECU-group rows, and 29 ECU-group records. Vehicle
`car_seriesid` joins to series `id`; vehicle `car_platformid` joins through
`platform-ecu-groups.car_platformid` to `ecu-groups.id`. Every vehicle ID is
unique, and every referenced series/platform/group key resolves. ECU-group
`modulegroup`, `defaultprotocolid`, and `defaultaddress` are retained as raw
fields. Protocol IDs 3 and 8 are not translated to Dart enums. `diagid` remains
a separate vehicle field because no source-backed join to those protocol IDs
or runtime ECU key strings was found.

These direct edges and their exact source rows are in
[`handler-routing.json`](../../assets/research/recovered-native/handler-routing.json).
The file also carries the 68 candidate ECU key strings, table return statuses,
FUNCTIONS rows, hashes, and the unresolved hops for the parent matrix builder.

## FUNCTIONS categories and visibility

The DEX `jl0.<init>` parser maps the first FUNCTIONS token through a packed
switch at `0x219902` to the `kl0` enum. This numeric source-table ID is distinct
from the enum ordinal:

| FUNCTIONS token 0 | `kl0` category |
| ---: | --- |
| 1 | `CF_IDENTIFICATION` |
| 2 | `CF_DTCREAD` |
| 3 | `CF_DTCCLEAR` |
| 4 | `CF_CONFIG` |
| 5 | `CF_LIVEDATA` |
| 6 | `CF_ACTORS` |
| 7 | `CF_CODING` |
| 8 | `CF_ADAPTIONS` |
| 9, 10 | `CF_UNKNOWN` |
| 11 | `CF_SERVICE_FUNCTIONS` |
| 12 | `CF_SERVICE` |
| 13 | `CF_PROGRAMMINGINFO` |
| 14 | `CF_INFODTCREAD` |
| 15 | `CF_INFODTCCLEAR` |

`jl0.b` is true exactly when token 1 parses to integer `1`. `fl0.g` adds the
parsed row to its FUNCTIONS collection only when this flag is true. In the 389
indexed rows, 243 pass that app list gate and 146 are filtered. Tokens 2–5 are
parsed but not stored in the visible `jl0` object; token 6 is stored as `jl0.c`
and later used to obtain localized text. All raw fields remain in the JSON.
Focused DEX excerpts are in
[`RE-02-functions-routing-excerpts.txt`](fixtures/RE-02-functions-routing-excerpts.txt).

There is a source-level service-category discrepancy worth carrying into
service-handler follow-up: the original retained `CF_SERVICE` rows are on
`cuX_CCP` and KOMBI-family keys; the BMS service-reset keys in the current Dart
catalog have other FUNCTIONS categories, including `CF_ADAPTIONS`. This alone
does not prove the reset implementation is unsafe or invalid: the original
table category and the separate service-reset protocol may represent different
surfaces. No write routing is inferred from the category label.

## Candidate ECU keys and native factory

`observed-ecu-keys.json` contains 68 DEX-observed strings. The legacy table
index has nonempty returns for 55 keys and 130 failures across 13 failure-only
keys and 10 attempted table names. Those failures are not absent-table proof.
A later private-JNI replay reclassified only the RE-09 `PARAMS` and
`PARAMS_TAB_GLOBAL` calls; 7 of the 13 keys faulted in the bounded loader, 6
returned native null (which the public wrapper normalizes to an empty array).
Do not convert either state into a vehicle capability claim.

The public DEX wrapper `NativeLibMotoScan.n(String,String)` at `0x4e4118`
calls private native `j(String,String)`, whose JNI entry is ELF RVA `0x6f6d84`.
Private native `n(String)` at `0x6f9574` is a different series-name API. The
private-JNI table method constructs a native metadata provider through the
factory at `0x88e3d0`; the exact provider class and its relationship to
diagnostic protocol executors remain opaque. The retained factory literal scan
is partial and only records exact string comparisons in that range; it is not
a complete ECU-key dispatch table. No suffix-based key joins are used.

## Remaining routing gaps

The source-backed edges stop at ECU-group metadata and per-key FUNCTIONS/table
rows. No proven link currently connects vehicle/group IDs to the 68 ECU key
strings, raw protocol IDs to application protocol enums, or a FUNCTIONS row to
every executable service/coding handler. The 5 local FUNCTIONS files without a
matching successful index entry stay separate. Empty results, native nulls,
probe faults, and nonempty rows retain distinct statuses in the matrix.
