# Actuator metadata and execution recovery

## Data relationships and row fields

The 1.110 DEX loader calls the native table accessor for each ECU key and the
`ACTUATOR`, `ACTUATORPOS`, and `ACTUATORCMD` tables. The relevant loader is
recovered in `assets/research/native-schema-disassembly.txt` around DEX offset
`0x217c64`:

- `z6` parses the actuator ID and localized-text ID.
- `x6` parses the position ID and parent actuator ID, plus integer metadata.
  Its field 4 is parsed and discarded.
- `y6` parses a command row's position ID, action, request bytes, optional
  response-prefix bytes, and duration. Its row ID is parsed and discarded.
- The loader joins position field `b` to actuator field `a`, then command field
  `a` to position field `a`. It sets the position's On, Off, and End flags from
  the nested action enum.

Text IDs are resolved through the recovered native `q` localized-text method.
`tool/native/build_actuator_catalog.py` reproduces those joins, preserves raw
command rows and parsed values, and writes the static Dart catalog used at
runtime.

## Execution sequence evidence

The older supplied 1.83 decompilation exposes the actuator worker in
`/tmp/motoscan-1.83-jadx/sources/s2/c.java` (`doInBackground`, lines 306–376).
It optionally sends the `Start` command, selects `On` or falls back to `Run`,
waits for the selected command's duration using one-second ticks, sends `Off`,
then sends `End` when present. Without an `End` row it calls `F0`; the BMW UDS
implementation's `F0` is a no-op that returns true. The command dispatch and
the `Start`/`Off`/`End` helpers are in
`/tmp/motoscan-1.83-jadx/sources/n2/e.java` (`a`, `M0`, `J0`, `I0`, `K0`, and
`L0`). The same class uses a 3000 ms adapter request timeout.

The 1.110 parser (`defpackage/y6.java`) matches the older row shape. Its
response-prefix column is decoded and discarded. The 1.83 `n3/b.java` parser
does the same, and the actuator dispatch path consumes the parsed command
bytes, not the discarded response prefix. The response status object
`m3/l.java` distinguishes `ERROR_OK` from transport/negative-response errors;
the actuator code does not compare a command-specific response tail.

This is source evidence for the older execution path, corroborated by the
current DEX parser shape. A complete 1.110 execution body was not recovered.
The Dart executor therefore keeps every request byte exactly as recorded and
checks UDS positive/negative service matching only. It never rewrites a request
to make a row's response prefix appear to match. For example, BMSX Off remains
`2F 62 50 00 FF` and its recorded prefix remains `6F 62 5C 00`.

## Runtime boundaries

- The executor requires an On/Run and Off pair and rejects unsupported service
  IDs or durations above 60 seconds.
- It sends Off after an attempted activation even when activation fails, times
  out, or returns a negative response; an End command is attempted afterward
  when present.
- Request timeout is 3 seconds, matching the recovered adapter calls. Delay
  duration comes from the native command field, capped at the observed maximum
  of 60 seconds.
- Native runtime tables were recovered through controlled offline native
  function execution. They do not establish that any command is safe for a
  particular motorcycle, support state, interlock, or service procedure.
- No motorcycle execution or hardware validation is claimed.
