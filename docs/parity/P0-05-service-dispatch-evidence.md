# P0-05 / RE-10 service dispatch evidence (checkpoint)

Status: partial source trace in progress. No production code changed. This
document separates the original FUNCTION category gate, controller factory,
handler selection, and payload handlers instead of treating them as one join.

## Correct FUNCTION category and list gate

In `jl0.<init>` (`/tmp/crossmoto-re09-dexdump.txt`, `0x2198b4`), FUNCTIONS
token 0 is parsed through the packed switch (`0x219902`, data `0x2199bc`) and
stored as a `kl0` enum. It is a numeric table ID, not the enum ordinal:

| Raw token 0 | Enum name | Retained on this key when token 1 is 1 |
| ---: | --- | --- |
| 8 | `CF_ADAPTIONS` | BMS-family entries |
| 11 | `CF_SERVICE_FUNCTIONS` | ABS/ESA/FSA/RDC/SAF/SLZ entries |
| 12 | `CF_SERVICE` | CCP and KOMBI entries |

Other recovered categories and the full mapping are in
[`handler-routing.json`](../../assets/research/recovered-native/handler-routing.json).
Token 1 becomes `jl0.b = (parseInt(token1) == 1)`; `fl0.g` retains the row only
when that flag is true (`0x217e12–0x217e38`). `f40.e` turns the category enum
into a visible category item; this alone does not identify an operation
handler. Focused DEX excerpts: [`RE-02-functions-routing-excerpts.txt`](fixtures/RE-02-functions-routing-excerpts.txt).

This corrects the old service-reset note's category-8 gate: raw ID 8 means
`CF_ADAPTIONS`; raw ID 12 means `CF_SERVICE`. The current Dart service-reset
catalog targets five BMS keys, whose source FUNCTIONS rows are ADAPTIONS, not
SERVICE. Original retained `CF_SERVICE` rows instead cover `cuX_CCP` and the
KOMBI keys (`cuX_KOMBI`, `cuX_KOMB03/17/18/46/50/53`, `cuX_KOMBB2`,
`cuX_KOMBHI/LO`, `cuX_KOMB_A`). This is a concrete capability-routing
discrepancy to resolve; it does not by itself prove an E12x write should run
for every CF_SERVICE row.

## Original modulegroup to controller and ECU-key selection

MainActivity constructs `fx(0)` at DEX `0x4e5b8a–0x4e5d96`. In the active
`fx.I(String)` path (`0x1b59d8`), the input is compared with exact ECU-group
`modulegroup` strings; it returns `cr` or `ak1` with a stored ECU address. The
factory results are then specialized after the VCI response: `cr.a()` /
`ak1.a()` call their `c(responseId)` selector, which returns an `el0` handler
with an exact `el0.e` ECU key. `sl0.c0()` passes that exact `el0.e` key to
`fl0.g(String)` to load its FUNCTIONS and other tables (`0x220e54–0x220e68`).
This is a source-backed group → controller → response discriminator → ECU-key
route, not a suffix match.

Confirmed `CF_SERVICE` routes:

| ECU group | Factory selector / address | Response ID → concrete handler | Service category |
| --- | --- | --- | --- |
| `G_MRKOMB` | `cr(23)` / 96 | `1017856` → `cuX_KOMBI`; `1017936` → `cuX_KOMB50`; `1017952` → `cuX_KOMB53`; `1017984` → `cuX_KOMB17`; `1018000` → `cuX_KOMB46`; `1019968` → `cuX_KOMB18`; `1020000` → `cuX_KOMB03`; `1020016` → `cuX_KOMBLO`; `1020032` → `cuX_KOMBHI`; `1020034` → `cuX_KOMBB2`; `1020037` → `cuX_KOMB_A` | `CF_SERVICE` |
| `G_MRSLZ` | `ak1(0)` / 64 | `1020064` → `cuX_CCP` | `CF_SERVICE` |

For these branches, `i15` / `f15` / `l15` descendants inherit `sl0`; their
service `C(dl0,int,Date,Date)` method is `sl0.C` (`0x21fe78`). The exact
KOMB/CCP construction branches are in JADX output `/tmp/re09-cr.java` and
`/tmp/re09-ak1.java`; source DEX offsets are `cr.c` `0x175288` and `ak1.c`
`0x297c4c`. Their 1.110 payload/readback behavior is documented by
[`service-reset-recovery.md`](../../assets/research/service-reset-recovery.md)
and the historical trace owner.

The original legacy KWP route is distinct: `D_MRKOMB` maps to `cr(6)` at
address 96. Its `cr.c` response selector can return KWP `qr`/`rr` handlers for
`MRKOMB18`, `MRKOMB46`, and `MRKOMBI` (K25), as well as separate `jr` handlers
for `MRKMB181`, `MRKMB461`, `MRKOMB71`, and `MRKOMB2D`. `qr.C` / `rr.C` use
their separate 0x3B service templates; they must not fall through to the UDS
E12x sequence. The available `FUNCTIONS` table key rows are `cuX_KOMB*`; no
direct association from those rows to legacy `MRKOMB*` labels has been found.

`CF_SERVICE_FUNCTIONS` rows are retained for nine keys: `cuX_ABS`,
`cuX_ABS9M`, `cuX_ABSVI`, `cuX_ESA`, `cuX_FSA`, `cuX_RDC`, `cuX_SAF`,
`cuX_SLZ03`, and `cuX_SLZ_4`. Their exact group/selector/response-key branches
are recorded in the source artifact; all returned service keys are `sl0`
descendants. A category row still does not prove each handler's specific
actions or request availability; those are being checked against the UI and
subclass dispatch.

## Exact artifacts and next trace

- [`handler-routing.json`](../../assets/research/recovered-native/handler-routing.json) preserves source row identities, FUNCTION category IDs/flags, group selectors, exact handler keys, and unresolved edges.
- [`RE-02-functions-routing-excerpts.txt`](fixtures/RE-02-functions-routing-excerpts.txt) contains the parser and loader excerpts.
- `assets/research/service-C-{sl0,qr,rr,pl0,nl0,er,il0}.txt` contains the service handler bodies.

Next: finish the click/menu path from the retained `CF_SERVICE` and
`CF_SERVICE_FUNCTIONS` rows into the specific service page, verify every
originally enabled per-key action and its handler subtype, and bind each
preflight/ACK/readback sequence to that key. Until this is complete, no broad
UDS or KWP service-family gate is justified.
