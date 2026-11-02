# RE-09: original PARAMS result decoding evidence

Source artifact: MotoScan 1.110 `classes.dex`, SHA-256
`869025551e5339811c300f2ae5ec92563c7e6b228d9498b8e835e2ac79283832`.
The disassembly cited below is a focused extraction from `/tmp/crossmoto-re09-dexdump.txt`.

## Recovered path

`fl0.g(String)` at DEX `0x217984` queries ECU-scoped `PARAMS`, `PARAMS_RES`,
and `PARAMS_TAB`. It attaches a `PARAMS_RES` record to its `PARAMS` parent when
`k21.b == j21.a`; TAB token 1 is attached to a result row when
`Ll21.a == k21.a` (`0x217a96-0x217aa8`, `0x217b8a-0x217bae`). `Ll21.a` is
`Integer.decode(TAB token 1)`; TAB token 0 is decoded then discarded
(`Ll21.<init>` at `0x26cb64-0x26cbbe`).

The `k21.<init>` parser at `0x26c788` maps `PARAMS_RES` semicolon fields as
follows (zero-based): `0` row key, `1` parent PARAMS key, `2` name/string,
`3` result data type, `4` secondary integer, `5` ignored, `6` raw C type,
`7` byte offset, `8` byte length, `9` optional mask (default `255`), `10` an
integer, `11` multiplier (default `1.0`), `12` divisor (default `1.0`),
`13` additive offset (default `0.0`), `14` integer decoded but not stored,
`15` a "1" boolean stored on the row, and `16` a "1" boolean evaluated but
not stored. The field extraction and defaults are visible at
`0x26c8ac-0x26cb02`.

The result enum is exact: field 3 values `1..9` map respectively to
`NUMBER`, `LIST`, `DIGITAL`, `ASCII`, `HEX`, `BITFIELD`, `DATETIME`,
`BMWUDSECUSN`, `TAB_GLOBAL`; all other values map to `UNKNOWN`.
The parser switch is at `0x26c918-0x26c958`, and enum constant names at
`sx2.<clinit>` `0x3751f8-0x3752e4`.

Both packed-switch payloads were decoded directly from the DEX bytes, not
inferred from nearby labels: `classes.dex[0x26cb38]` has first key 1 and nine
relative targets (`0x1e,0x1b,0x18,0x15,0x12,0x0f,0x0c,0x09,0x06`), yielding
the result enum mapping above from switch at `0x26c918`. The C-type switch at
`0x31dac4` uses payload `classes.dex[0x31dbd4]`, first key 2 and six relative
targets (`0x60,0x59,0x54,0x16,0x11,0x04`); their resolved instruction targets
are listed in the fixture excerpt.

## Numeric extraction and scaling

`j21.b(byte[])` at `0x26c1d4` decodes a PARAMS response. It checks response
length against `j21.d + k21.g + k21.h` (`0x26c25c-0x26c282`). Here `j21.d` is
the PARAMS response/base offset; `k21.g/h` are result offset/length. For
numeric decoding, it passes the **full response**, `k21.f` C type, and absolute
offset `j21.d + k21.g` to `ob2.D(byte[],String,int)` (`0x26c610-0x26c616`).
Other formatting branches use the separately copied result slice. The consumer
`sl0.p(II)` at `0x21f4bc` checks response byte 0 for `0x62` (positive response
to UDS `0x22`) or `0x7f` (negative response) and passes the unchanged positive
response to `j21.b` (`0x21f59a-0x21f5c4`). Thus for observed requests
`j21.d == 3`, the base skips SID plus two-byte DID. This is the original app's
response framing. A caller that strips SID+DID before decoding must rebase this
offset (subtract 3 for this layout); the source does not establish another
client's framing.

`ob2.D` at `0x31d9a4` wraps the bytes in a **BIG_ENDIAN** `ByteBuffer`
(`0x31d9b4-0x31d9c0`). It dispatches by C type (`0x31d9d4-0x31dab6`):

| C type | Operation | Signedness / result |
|---|---|---|
| `unsigned char` | `get(offset) & 0xff` | unsigned 8-bit |
| `unsigned int` | `getShort(offset) & 0xffff` | unsigned 16-bit (the app's label maps to `dtUNSIGNED_SHORT_INT`) |
| `char` | `get(offset)` | signed 8-bit |
| `signed char` | `get(offset) & 0xff` | unsigned 8-bit; source label maps to `dtUNSIGNED_CHAR` |
| `int`, `signed int` | `getShort(offset)` | signed 16-bit (the app leaves the initialized `dtSHORT_INT`) |
| `unsigned long` | `getInt(offset) & 0xffffffffL`, then int cast | low 32 bits; Java API returns int, so values above `2^31-1` become negative before scaling |
| `short`, `unsigned short`, other unmatched labels | returns `0` | unmatched labels take the fallback `dtSTRING` branch; `data*` maps `dtDATA`; `BITFIELD` maps `dtBITFIELD`; none has a numeric switch case |

The actual byte readers and masks are at `0x31dad0-0x31db8c`; signed and
unsigned branch targets are explicit. The textual labels' mapping through
`gx2` is at `0x31d9d4-0x31daba`; note both the 16-bit width for database
labels `int`/`unsigned int` and that `signed char` selects the unsigned-char
enum. The type dispatch's fallback goes to `dtSTRING` (or `dtDATA` for a
`data*` prefix) and the numeric helper returns zero, not a raw fallback. The
call-site bounds check is at
`0x26c25c-0x26c270`.

For the scalar numeric display path, `j21.b` computes
`raw * k21.l / k21.m + k21.n` (`0x26c610-0x26c62a`). Note the source performs
the division directly; it does not guard divisor zero. Multiplier/divisor/
offset parsing/defaults are at `0x26ca3a-0x26cab0`. A sample FSA battery voltage
record has type `unsigned char`, multiplier `1.0`, divisor `10.0`, offset `0.0`
(`assets/research/recovered-native/runtime-tables/cuX_FSA/PARAMS_RES.json`,
row key 990), hence formula is raw / 10 for that record.

`LIST` results compare the extracted raw integer to `PARAMS_TAB` list values;
`DIGITAL` results match bitfield entries using `ob2.D` plus mask `k21.i`
when `k21.j` is true (`0x26c53a-0x26c5a0`). Other result types have distinct
format paths in `j21.b`. The switch branches identify labels but not all
end-user formatting/unit semantics; do not infer a global unit mapping.

## Boundaries

This recovers the app's Java-side result parser and its checked UDS response
prefix. It does not establish full native transport behavior, write behavior,
or safety of sending arbitrary PARAMS requests. `unsigned long` cannot be
modeled faithfully above 32 bits by this `int` return path. Since the original
helper maps unmatched types to zero, a parity implementation should preserve
the raw bytes alongside a decoded status rather than silently copy that
fallback. Date, OEM-specific and global-table interpretations need separate
fixtures before claiming parity.
