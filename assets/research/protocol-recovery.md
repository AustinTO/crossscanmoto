# MotoScan ELM327 protocol recovery

This note transcribes behavior visible in the supplied DEX disassembly. `vq4` is the VciELM327 transport. Commands below are the literal strings passed to `vq4.v(String)`; its implementation (near `vq4.v`, file offset `46ab8c`) performs transport I/O, so these are command order, not an assertion about adapter response semantics.

## Common reset/configuration

`vq4.<init>` at `46bf24` builds the initial command list in this exact order:

1. `ATWS`
2. `ATL0`
3. `ATSP0`
4. `ATH1`
5. `ATE0`
6. `ATS0`

The array construction order is explicit at `46bf7e–46bf9e` (`filled-new-array` inputs are registers v1..v6). This is a stored list; execution timing relative to protocol-specific setup depends on the caller. `vq4.x(protocol, numericId)` later performs protocol selection and records the `(protocol,id)` only after all commands in that branch succeed (`46b462–46b470`).

The connection initializer `vq4.o()` at `46a980` sends one additional `ATWS` before iterating this stored list. Therefore the executed reset prefix is `ATWS` followed by the list, which begins with a second `ATWS`. It retries each stored command once when the first call returns false, then returns false if the retry also fails. `vq4.v()` defines generic AT/ST success as at least one response line containing `OK` (`46ac18–46ac60`); `ATWS` uses its special four-second path and checks for `ELM32`. After reset commands, it calls `vq4.n()` to identify the adapter, then waits four seconds. In that wait it sleeps in 5 ms increments, issues `ATRV` once at approximately the two-second mark, and returns after the four-second mark (`46aab0–46ab1a`). The Dart initializer preserves this command check, one retry, and two-second/ATRV/two-second ordering; delay is injectable for checks.

## Protocol enum values

`ox2` enum ordinals (class initializer `374b70–374d70`) are:

| Ordinal | Enum |
|---:|---|
| 0 | UNKNOWN |
| 1 | AUTOMATIC |
| 2 | ISO |
| 3 | KWPS |
| 4 | KWPF |
| 5 | VPW |
| 6 | PWM |
| 7 | CAN11500 |
| 8 | CAN11250 |
| 9 | CAN29500 |
| 10 | CAN29250 |
| 11 | BMW_DCAN |
| 12 | BMW_FAST |
| 13 | BMW_BIKE_KWA |
| 14 | BMW_BIKE_KWA2 |
| 15 | BMW_BIKE_FTE_INIT |
| 16 | BMW_BIKE_FTE_WORK |
| 17 | BMW_BIKE_KWP |
| 18 | BMW_BIKE_UDS |
| 19 | SUZUKI_BIKE_KWP |
| 20 | SUZUKI_BIKE_KWP_INIT |

The displayed Java fields are obfuscated (`ox2.X/Y/Z/c/d/s1/x/y`); use ordinal/name mapping rather than field letters. In particular, `ox2.x` is `BMW_BIKE_KWA`, `ox2.y` is `BMW_BIKE_KWA2`, `ox2.X` is `BMW_BIKE_FTE_INIT`, `ox2.Y` is `BMW_BIKE_FTE_WORK`, `ox2.Z` is `BMW_BIKE_KWP`; `BMW_BIKE_UDS` is ordinal 18.

## BMW setup branches in `vq4.x`

The method receives `(ox2 protocol, int id)`. It dispatches on `protocol.ordinal()` via packed switch (`46ad44`). The raw DEX payload at file offset `0x46b474` decodes as `size=20`, `firstKey=1`; targets are relative to switch PC `0x32` code units. The exact key → target-PC table is: `1:3bd, 2:3b6, 3:3af, 4:3aa, 5:3a3, 6:39c, 7:395, 8:38e, 9:387, 10:380, 11:395, 12:3aa, 13:318, 14:2b2, 15:26d, 16:265, 17:1ff, 18:c6, 19:a1, 20:3b`. Sequences are short-circuiting: any failed command returns false, and the method does not update the selected protocol/id.

- **BMW_DCAN (ordinal 11):** target PC `0x395`, which emits `ATSP6`.
- **BMW_FAST (ordinal 12):** target PC `0x3aa`, which emits `ATSP5`.
- **BMW bike KWA (ordinal 13):** target PC `0x318` (block at `46b310`) emits shared commands, beginning `ATPC` → `ATAL` → `ATSH%02xF3` …; id is `%02x`.
- **BMW bike KWA2 (ordinal 14):** target PC `0x2b2` (`46b244`), a distinct branch; do not conflate with KWA.
- **BMW bike FTE init/work (ordinals 15/16):** targets `0x26d`/`0x265` (`46b1ba`/`46b1aa` vicinity), specialized paths described below.
- **BMW bike KWP (ordinal 17):** target PC `0x1ff`, distinct from KWA/KWA2.
- **BMW bike UDS (ordinal 18):** target PC `0xc6`, which first checks whether current protocol/id already match; otherwise executes the full BMW bike setup sequence below.
- **BMW bike FTE init/work (ordinals 15/16):** these share specialized initialization logic (`46afbe–46b188`): setup uses `ATPC`, `ATAL`, dynamically built `ATSH%02xF1`, `ATWM81`, `ATST60`, and a final protocol command; another path constructs `ATWM80`, `ATSH80%02xF1`, `ATSP0`, and sends `ATST50`, `ATSTA0`, then a final protocol command. Exact distinction is guarded by adapter capability/state fields (`Lil`); do not collapse to a single unconditional sequence. See limits below.

Suzuki ordinals 19 and 20 target PCs `0xa1` and `0x3b` respectively; their complete command paths are outside this recovery note.

Generic protocol commands map by raw switch key/enum ordinal as follows, from dispatch targets `46b3e0–46b462`: `AUTOMATIC(1)` → `ATSP0`; `ISO(2)` → `ATSP3`; `KWPS(3)` → `ATSP4`; `KWPF(4)` → `ATSP5`; `VPW(5)` → `ATSP2`; `PWM(6)` → `ATSP1`; `CAN11500(7)` → `ATSP6`; `CAN11250(8)` → `ATSP8`; `CAN29500(9)` → `ATSP7`; `CAN29250(10)` → `ATSP9`. The disassembly's target table is the source of truth even where this mapping is unexpected. Keys 11–12 share targets with keys 7/4 respectively. BMW and Suzuki ordinals 13–20 dispatch to specialized code blocks.

## Confidence and limits

- Literal defaults, enum ordinals, and command order are direct DEX evidence.
- `vq4.x` branch IDs derive from `ox2` ordinal dispatch; enum initializer gives the names and order.
- Some FTE preconditions depend on `Lil` capability/manufacturer metadata. The disassembly shows the command families but this extraction does not fully decode those predicates; implementation should preserve the guards or gather more metadata evidence before selecting an FTE path.
- The `ATSP*` mapping is the app's emitted command mapping, not a general claim about every ELM clone's implementation.

## BMW bike UDS setup and payload framing

The enum-18 switch entry is verified directly from the raw packed-switch payload at DEX offset `0x46b474`: key 18 targets PC `0xc6`. `vq4.x` returns success without I/O when its cached protocol and id match (`46ae6c–46ae7c`). Otherwise the exact mandatory command sequence is:

1. `ATSPB`
2. `ATPBC101`
3. `ATSH6F1`
4. `ATFCSH6F1`
5. `ATFCSD{idHex}300008`
6. `ATFCSM1`
7. `ATCEA{idHex}`
8. `ATCM7FF`
9. `ATCF6{idHex}`
10. `ATST90`
11. `ATBI`

Each step is short-circuit checked. `idHex` is Java `String.format("%02x", id)`, lowercase and minimum width two. There is no ID range guard in `vq4.x`; values above `0xff` expand beyond two digits. Do not infer an 8-bit upper bound from the format string alone.

After `ATBI`, extra commands are conditional on adapter metadata (`Lil.Y`, enum `xq4`) and the metadata object being present. The accepted first set is `OBDLINK_LX`, `OBDLINK_MX`, `OBDLINK_MX_PLUS`; the accepted second set is `VLINKER_FS`, `VLINKER_MC`, `VLINKER_MS`, `VLINKER_FD`, `CARISTA_EVO`. The recognized `VIAKEN_STN1170` profile is **not** in either set. Accepted profiles receive `STCSEGT1`, `STCFCPC`, then `STCFCPA 6F1{idHex},6{idHex}F3`; the first two call results are ignored, the final call result controls setup success. Evidence: guard sets and commands at `46afbe–46b0da`; enum names at `46c5e4–46c75a`; metadata mapping at `46a62c–46a75c`.

For requests, `vq4.t([BII)` converts request bytes to uppercase hex (`kb2.o`, byte-to-hex helper at `31bda0`), calls `vq4.r(String)` which appends `\r` and writes using the transport charset (`46c162–46c21e`), waits for the prompt in `vq4.q(timeout)`, then passes response tokens through `yl4.v(responseLines, protocol)` (`46bd68–46beac`). `q()` splits on CR, filters ELM boilerplate and extracts hexadecimal spans. For enum 18, `yl4.v` only decodes when the response-token list has exactly one entry: it drops that entry's first character, hex-decodes the remainder, reads byte index 2 as the payload length, and copies that many bytes starting at index 3 (`45a496–45a4e8`). It does not reassemble multi-line ISO-TP in this branch. The Dart request link implements this single-token layout with strict truncation and hex checks. The recorded-format fixtures are synthetic; they verify byte placement only and do not claim to be captured hardware traffic. NRC `0x78` is surfaced as unsupported because the recovered reader ends at the prompt and no final-response continuation was established.
