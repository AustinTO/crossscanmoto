# RE-09: historical live-data decoder comparison

This compares the static Java/Kotlin decoder in MotoScan 1.83 with the
1.110 source evidence in [RE-09-source-evidence.md](RE-09-source-evidence.md).
It is a source comparison, not an execution of either app.

## Artifacts and method locations

MotoScan 1.83 APK SHA-256:
`f4b168234e2b3a042f35f3c0e8ee27a19e47bec0b32d01f1d6efa235ab39eacc`.
Its extracted `classes.dex` SHA-256 is
`fa527331a06735012c0b3f680940c12096d543e8ed1b22df054e4977c1394ffb`.
Focused raw disassembly excerpts and offsets are preserved in
[`fixtures/re09-183-decoder-excerpts.txt`](fixtures/re09-183-decoder-excerpts.txt).

In 1.83, `r3.b.b([B)` at DEX `0x46cacc` checks response byte 0 for `0x62`,
checks the response length against `base + row offset + row length`, then calls
`v3.e.e([B,I,r3.c)` at `0x46cb38`. That method copies the result range beginning
at `base + row offset`; its NUMBER branch calls `v3.e.i([B,String,I)` at
`0x484c6c` with the original full response, the row's C-type string and
absolute offset `base + row offset`. For the observed UDS layout with base 3,
this selects the bytes after SID and DID. 1.110 `sl0.p(II)` similarly checks the positive response
and calls `j21.b([B)`; `j21.b` checks `base + row offset + row length` and
passes the full response plus the absolute offset to `ob2.D`.

Thus framing and numeric read boundaries match: numeric reads use the full
response and absolute `base + row offset`. 1.83 also creates a row slice for
other type-formatting branches. The 3-byte base is established for the
observed request layout, not every caller or transport.

## NUMBER behavior

The compared numeric behavior matches at source level:

| Behavior | MotoScan 1.83 | MotoScan 1.110 |
|---|---|---|
| Byte order | `BIG_ENDIAN` | `BIG_ENDIAN` |
| `unsigned char` | 8-bit byte masked with `0xff` | 8-bit byte masked with `0xff` |
| `char` | signed 8-bit byte | signed 8-bit byte |
| `signed char` | maps to unsigned-char enum; 8-bit masked | same mapping and read |
| `int`, `signed int` | signed `getShort` (16-bit) | signed `getShort` (16-bit) |
| `unsigned int` | `getShort`, mask `0xffff` (16-bit) | same |
| `unsigned long` | `getInt`, mask to low 32 bits, cast to `int` | same |
| Unmatched labels, including `short` / `unsigned short` | returns initialized zero | returns initialized zero |
| `unsigned int` read overrun | logs and returns zero | same capacity check/fallback |
| Scale | `raw * multiplier / divisor + offset` | same formula |
| Display precision | `%.0f` if multiplier and divisor are both 1; otherwise `%.2f` | same condition and formats |

1.83 parses the relevant row fields at `r3.c.<init>` (`0x46c1d0`): C type at
index 6, byte offset/length at 7/8, optional mask at 9 (default 255), multiplier
at 11 (default 1), divisor at 12 (default 1), and additive offset at 13
(default 0). The NUMBER formatting and precision branch is in `v3.e.e`
(`0x48502e-0x4850de`). 1.110's corresponding row parser and formula are
documented in the source evidence. Numeric helper dispatches and their switch
targets are in the focused excerpt.

These matches confirm decoder behavior, not generalized physical-unit
semantics or per-ECU layout correctness. Both versions retain the 32-bit
`unsigned long` limitation and zero fallback for unknown numeric C labels.
The source alone does not prove identical locale-dependent output on every
device or app runtime.

## Result types 2–9 and common tail

The 1.83 enum at `m3.o.<clinit>` (`0x25b190`) assigns the same numeric IDs to
UNKNOWN and result types 1–9 as 1.110's `sx2`; both parsers read result type
from token 3. In 1.83 the formatter switch is `v3.e.e` (`0x484eca`); in 1.110
it is `j21.b` (`0x26c296`). Comparing the branch bodies and their helpers shows
these static behaviors match:

| Type | 1.83 and 1.110 source behavior |
|---|---|
| LIST | Empty result TAB list gives `-`. Otherwise decode using the row C type and response offset, match TAB token 2's integer to the decoded value, return token 3's integer text ID; no match gives `-`. 1.83 parser `r3.d.<init>` (`0x46c960`) and 1.110 `l21.<init>` (`0x26cb64`) both parse `0x` values with `Integer.decode`, decimal values with `Integer.valueOf`, and token 3 with `Integer.decode`. |
| DIGITAL | Same lookup as LIST. When token 9 is nonempty, use `1` iff `(raw & mask) > 0`, else `0`; both versions use the same strict positive test. |
| ASCII | Literal `ASCII-VALUE`; copied bytes are not decoded. |
| HEX | Uppercase, contiguous hex bytes. 1.83 uses `v3.d.g`; 1.110 uses `kb2.o`. |
| BITFIELD | Literal `BITFIELD-VALUE`; copied bytes are not decoded. |
| DATETIME | If token 10 equals 1, render copied bytes `[2],[1],[0]` as `%02x.%02x.20%02x`; otherwise render uppercase contiguous HEX. Neither source checks that the copied row slice has at least three bytes before indexing. |
| BMWUDSECUSN | Treat byte 0 as signed and branch on `< 48`. Below 48, each signed byte is converted to a char, printable `[32,127)` bytes receive `+48`, other bytes become spaces, and output is not trimmed. Otherwise emit printable signed-byte chars, spaces for other bytes, then trim. 1.83 delegates to `v3.d.f/e`; 1.110 implements this inline and delegates the second path to `kb2.n`. |
| TAB_GLOBAL | Start with uppercase HEX. Empty global rows, missing header columns, or missing key preserve HEX. Find key/value columns in the first row, interpret the copied bytes with `new BigInteger(bytes).intValue()` (signed big-endian low 32 bits), then scan rows for the decimal key and return its value. Both scan every row, including the first header row. 1.83 implements this in `r3.e.d` (`0x46c620`); 1.110 does it inline. |

The common tail also has the same conditions in both versions: when ordinary
`PARAMS_TAB` rows exist and the value is not `-`, parse the returned text ID
and localize it; otherwise, when that list is empty, attach the unit string
unless it is `-`. Both versions load `GENERAL_VALUES_UNITS` by `NativeLib.p`,
parse row token 0 as the ID and token 1 as displayed unit text, and discard
token 2. The 1.83 loader is `n2.b.m` (`0x262364-0x2623cc`); 1.110 loads the same
table in `fl0.g` (`0x2179c2-0x217a0c`).

The common tail does not check the result format before parsing a non-dash value
as an integer. Therefore, attaching ordinary TAB rows to a literal marker or
non-integer formatted result can throw during the common-tail parse in either
version. The compared source branches preserve this edge behavior.

There is one source-level localization-path change. 1.110 calls `Les0.s(id)`:
its mode 2 returns `Dummy text`; other modes call `NativeLibMotoScan.I(id)`.
1.83 calls `i4.c.g(id)` (`0x23fd8c`), which dispatches to the configured
translator's live-data method. `MainActivity.w0` installs `j2.k`; that
implementation calls `NativeLibMotoScan.G(id)` and sets the selected language
through `NativeLibMotoScan.J`. If the translator is not installed, the 1.83
fallback translator returns `Dummy text`. Thus the branch returns and common
tail conditions match, but identical localized strings are not established:
the native entry points (`I` vs `G`) and 1.83's language-configurable
translator path differ, and native outputs were not compared here.

The source comparison establishes behavior from the Java/Kotlin call sites and
helpers, not matching native table contents or localized outputs.

## Conclusion

NUMBER and result types 2–9 have matching decoder branch logic, including
byte extraction, masks, fallback strings, date/OEM transforms, global-table
lookup shape and unit visibility. The material source-level drift is the
localized TAB text dispatch (`NativeLib.I` vs configurable `NativeLib.G` path);
parity of those translated strings needs an original native-output oracle.
This remains static evidence, without original-app execution traces or
hardware checks.
