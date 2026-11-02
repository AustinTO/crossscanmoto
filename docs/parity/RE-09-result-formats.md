# RE-09: original PARAMS result formats

This note follows MotoScan 1.110 `classes.dex` (SHA-256
`869025551e5339811c300f2ae5ec92563c7e6b228d9498b8e835e2ac79283832`). The
instruction excerpts and switch table are pinned in
[`re09-result-format-excerpts.txt`](fixtures/re09-result-format-excerpts.txt).
Raw DEX control flow is authoritative where JADX's reconstruction differs.

## Dispatch

`j21.b(byte[])` at `0x26c1d4` first requires a nonempty response beginning with
`0x62` per result row, checks `response.length >= j21.d + k21.g + k21.h`, and
copies the result slice `[j21.d + k21.g, j21.d + k21.g + k21.h)`. Its packed
switch at `0x26c296` has binary payload at `classes.dex[0x26c75c]`; decoded
keys `1..9` map to these targets and result types:

| `PARAMS_RES` field 3 | Target | Result behavior |
|---:|---:|---|
| 0 / default | `0x26c29c` | value `"-"` |
| 1 | `0x26c608` | `NUMBER` |
| 2 | `0x26c5a6` | `LIST` |
| 3 | `0x26c532` | `DIGITAL` |
| 4 | `0x26c522` | `ASCII` |
| 5 | `0x26c50e` | `HEX` |
| 6 | `0x26c4fe` | `BITFIELD` |
| 7 | `0x26c49a` | `DATETIME` |
| 8 | `0x26c426` | `BMWUDSECUSN` |
| 9 | `0x26c2a8` | `TAB_GLOBAL` |

The numeric packed-switch target calculation is `switch_address + 2 *
relative_code_units`; the raw DEX decode is recorded in the fixture.

## Per-type output

- **NUMBER:** `ob2.D(fullResponse, k21.f, j21.d + k21.g)` reads according to
  the source C-type dispatch in [the byte-decoder evidence](RE-09-source-evidence.md). Specifically, the observed labels map as
  `unsigned char`/`signed char` -> unsigned 8-bit, `char` -> signed 8-bit,
  `unsigned int` -> unsigned 16-bit, `int`/`signed int` -> signed 16-bit, and
  `unsigned long` -> unsigned 32-bit returned through an `int`. Other labels
  take the helper's zero-return path. It then
  computes `raw * k21.l / k21.m + k21.n`. If both multiplier and divisor equal
  `1.0`, the result is formatted with `String.format(Locale.getDefault(),
  "%.0f", value)`; otherwise it uses `"%.2f"`. `k21.n` is added after
  division. A zero divisor has no guard.
- **LIST:** if attached `PARAMS_TAB` rows are absent, output `"-"`; otherwise
  decode raw using `ob2.D`, match `Ll21.b`, and use the matching `Ll21.c`
  integer's decimal string. No matching value yields `"-"`.
- **DIGITAL:** same row lookup as LIST. If the mask-presence flag `k21.j` is
  true, transform the decoded raw value to `1` when `(raw & k21.i) > 0`, else
  `0`; otherwise use raw unchanged. Then match `Ll21.b` and output `Ll21.c`.
- **ASCII:** literal value `"ASCII-VALUE"`; this branch does not decode the
  copied response bytes.
- **HEX:** uppercase, contiguous hex for each copied byte (`kb2.o`); no spaces
  or separators.
- **BITFIELD:** literal value `"BITFIELD-VALUE"`; this branch does not decode
  the copied bytes.
- **DATETIME:** if `k21.k != 1`, same uppercase HEX as above. If `k21.k == 1`,
  use copied bytes at positions `[2], [1], [0]` in Java format string
  `"%02x.%02x.20%02x"`.
- **BMWUDSECUSN:** inspect copied byte 0 as a signed byte. If it is `< 48`,
  process every byte by signed-byte-to-char conversion: retain characters in
  `[32,127)` after adding 48 to the original byte; replace other characters
  with a space. Otherwise call `kb2.n`, which converts bytes to printable
  ASCII characters in `[32,127)`, replaces others with spaces, then trims the
  result.
- **TAB_GLOBAL:** start with uppercase HEX fallback. If `k21.q.d` has rows,
  split the first row on `;` and find token indexes matching `jw.X` and `jw.Y`.
  If both columns exist, convert the copied bytes with
  `new BigInteger(slice).intValue()` (signed, big-endian two's-complement,
  low 32 bits), then find a lookup row whose `X` column equals the decimal
  integer string and return its `Y` column. Missing headers or a missing value
  keep the HEX fallback. There is no C-type or scale transform in this branch.

`PARAMS_TAB_GLOBAL` rows are attached only for result enums LIST, DIGITAL, and
TAB_GLOBAL: `fl0.g` matches parsed `jw.x` to `k21.a`, calls
`NativeLibMotoScan.p(jw.y)`, fills `jw.d` with returned rows, then stores `jw`
as `k21.q` (`0x217ab8-0x217b60`). Here `jw.X`/`jw.Y` are parsed from source-row
tokens 3 and 5, and `jw.y` from token 2 (`jw.<init>(String)` at `0x1b02cc`).
The bounded native probe has 55 empty `PARAMS_TAB_GLOBAL` responses and 13
invalid-row-count errors across 68 observed ECU keys; the errors also occur
for the other queried tables, so they do not prove those 13 tables are absent.
The global-name query returns no rows. Consequently there is no concrete
TAB_GLOBAL mapping fixture; see [global recovery status](RE-09-global-values.md).

## Localization, units, and flags

After each type branch, the common tail applies two conditional transforms:

1. If the `PARAMS_TAB` list is **nonempty** and value is not `"-"`, parse the
   value as an integer and call `Les0.s(int)` (`0x26c69e-0x26c6c6`). The value
   is usually the decimal string from `Ll21.c`, i.e. TAB token 3, not a raw
   sensor value. In `Les0.s`, mode `c == 2` returns literal `"Dummy text"`;
   all other modes call `NativeLibMotoScan.I(int)`, whose public wrapper calls
   native `t(int)` (`0x24207c-0x2420a4`, switch payload `0x2420a8`).
2. If the `PARAMS_TAB` list is **empty**, set the unit string to `k21.s` unless
   it equals `"-"`; otherwise set it to `""` (`0x26c6c8-0x26c6ea`). The loader
   sets `k21.s` from `GENERAL_VALUES_UNITS` by matching `nq4.a == k21.e` and
   assigning `nq4.b` (`0x217bf6-0x217c12`). `nq4` parses token 0 as the integer
   key and stores token 1 as text; token 2 is parsed but discarded
   (`nq4.<init>` at `0x468f58`). No language-ID join is visible in this DEX
   loader. The captured row `2;V;105477` associates unit key 2 with text `V`.
   The recovered 486-row association map contains 58 display strings,
   including `0/1`, `TEXT`, and `DATA`; not every string is a physical unit
   ([global recovery status](RE-09-global-values.md)).

The result name `k21.r` is produced from the integer code in `PARAMS_RES` token
14 by `wr1.R(code, Ly72.d)`; the result object receives name/value/unit as
`Llx2.f/h/i`. For `Ly72.d` (`LNG_LIVE_DATA`), `wr1.R` resolves `k21.r` through
the native live-data text lookup path. The UI
renderer at `0x12d704-0x12d764` displays the name from
`f` and builds value text as `h + " " + i`. `k21.o` (field
15) is separately checked by `sl0.o` when selecting rows for its list; it is
not the mask flag. `k21.j` is the digital mask-presence flag, set when
`PARAMS_RES` field 9 is nonempty; `k21.i` is that decoded mask (default 255).
`k21.k` (field 10) selects the DATETIME hex-vs-date output. Separately,
`j21.f` is true when `PARAMS` field 6 equals `"1"`; `sl0.o` filters parent
parameters on it (`0x21f6de-0x21f6e6`). `k21.o` is true when result field 15
equals `"1"` and is checked when that view list iterates results. `PARAMS`
field 7 is compared with `"1"` but its result is discarded; `PARAMS_RES`
field 16 is also compared with `"1"` but not stored. These flags do not
change the byte decoding branches in `j21.b`.

`sl0.p(II)` accepts positive response `0x62` and negative response `0x7f`,
then passes the unchanged byte array to `j21.b`; `j21.b` itself decodes only
`0x62`. Thus a `0x7f` input produces one `"no data available"` row per result
record. Empty arrays are handled by the caller as an empty result model. A
non-`0x62` byte array passed directly to `j21.b` also produces
`"no data available"` rows. A `0x62` response too short for a row causes that
row to be skipped; if all rows are skipped, the returned collection is empty.

## Worked traces from recovered rows

These traces combine independently recovered table rows with explicit sample
response bytes; the byte values are illustrative, not captured vehicle
responses.

1. **NUMBER:** FSA PARAMS key 990 is request `22 E1 42` with base offset 3;
   result key 4220 has type NUMBER, unsigned-char C type, offset 0, length 1,
   multiplier 1, divisor 10, additive offset 0. For response
   `62 E1 42 EA`, raw is 234, transformed value is 23.4, and US-locale text is
   `23.40`. The captured GENERAL_VALUES_UNITS row `2;V;105477` associates
   unit `V`, so the UI value text is `23.40 V` (US locale). This result has no
   PARAMS_TAB children.
2. **LIST:** FSA result key 4206 (parent PARAMS 982) is unsigned char, offset 0,
   length 1, LIST. Its TAB rows map value 0 to ID 107898 and value 1 to ID
   107899. For response `62 E1 08 01`, the value path is
   `Ll21.c=107899` then `Les0.s(107899)` (native `I(int)` result unless mode
   2, where it is `"Dummy text"`); unit is blank because TAB rows exist.
3. **Masked DIGITAL:** KOMB53 result 6383 (parent PARAMS 1391, request
   `22 E1 20`) is unsigned-int, offset 0, length 2, mask `0x0010`; TAB maps 0
   to ID 106221 and 1 to ID 106222. For `62 E1 20 00 10`, source C-type
   decoding gives unsigned 16-bit `16`; mask result is 1; output path is
   `Ll21.c=106222` then `Les0.s(106222)`; unit is blank.

## Known source limits

ASCII and BITFIELD are literal placeholders in this method. TAB_GLOBAL's
native query yielded only empty results or unclassified errors in the bounded
probe, so there are no recovered header/value rows to exercise its lookup.
DATETIME indexes three bytes without checking that declared slice length is
at least three. Primitive numeric reads are based on C-type width; the caller
checks the table-declared slice end but not that `k21.h` is at least that
width. The original app also uses int-returning numeric helpers, so wide
unsigned representations above 32 bits are not retained faithfully. Numeric
formatting uses the process default locale; this worked trace records only the
US-locale rendering (`23.40`), not locale-specific separators for other
settings.
