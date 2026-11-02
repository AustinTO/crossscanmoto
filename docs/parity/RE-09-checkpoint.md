# RE-09 decoder checkpoint, 2026-11-02

Baseline: `adf98d171d0c828e60e6d7cf6fbb4d06e87c9437`.

All nine original result branches are implemented: NUMBER, LIST, DIGITAL,
ASCII, HEX, BITFIELD, DATETIME, BMWUDSECUSN and TAB_GLOBAL. Raw bytes remain
available alongside decoded values, placeholders and failures. The original
ASCII/BITFIELD literals are explicitly marked as placeholders. Source-backed
labels, units, masks and table values are joined by ECU and numeric keys.
The original native `unknown text` fallback is retained with provenance.

The catalog contains 230 UDS requests across 21 ECU keys, 486 result layouts
and 665 tab rows. The numeric oracle covers all 268 NUMBER layouts with 804
boundary vectors, including Java Formatter outputs. The non-numeric oracle
covers all 218 remaining layouts with 827 vectors. Expected values come from
independent source-based Python calculations and an isolated Java formatter;
chosen response bytes are synthetic, not original motorcycle captures.

## Source and implementation

- `RE-09-source-evidence.md`, `RE-09-result-formats.md`, their raw DEX excerpts,
  and `RE-09-historical-comparison.md` retain exact methods and offsets.
- `lib/diagnostics/live_data_definitions.dart`: typed results, original C-type
  dispatch quirks, scaling, Java-compatible decimal rounding, table/global
  lookup, unit rules and explicit malformed-input handling.
- `lib/live_data_page.dart`: decoded text plus raw bytes, with target identity
  checks before and after the read. Existing generation checks remain intact.
- `tool/native/build_parameter_catalog.py`: deterministic scoped joins.
- `tool/native/build_parameter_goldens.py` and `build_result_layout_goldens.py`:
  independent source-based fixtures and retained capture provenance.

APK SHA-256: `bfc07ce264a0c35df9d63558f4fa64c4bd3dd845903d3e0417532250ea0e7e58`.
DEX SHA-256: `869025551e5339811c300f2ae5ec92563c7e6b228d9498b8e835e2ac79283832`.
Both 1.110 and the separately fingerprinted 1.83 decoder were inspected.

## Verification

- `flutter test --no-pub --concurrency=1`: **968 passed**.
- `flutter analyze --no-pub`: **No issues found**.
- `python -m unittest discover -s tool/native -p 'test_parameter*.py' -v`:
  **5 passed**, including native-row/capture/file provenance and deterministic
  numeric fixture generation.
- Catalog and both layout fixture generators reproduce byte-identical output.
- `git diff --check`: passed.

## Remaining inventory dependencies

The actual public table wrapper calls private JNI `j`, not the unrelated
native `n` series API; the old note is corrected. The JNI probe matches all
21 retained PARAMS controls. TAB_GLOBAL queries across 68 candidate keys yield
55 empty arrays, six nulls (mapped to empty by the public wrapper), and seven
offline probe faults. Faults do not prove table absence. RE-02/RE-05 must settle
those keys and the complete original inventory before universal ticket parity
can be asserted. The generic global decoder is implemented and independently
tested, but no actual type-9 row exists in the retained catalog.

NUMBER formatting accepts caller-supplied decimal separator and zero digit;
Java US/German/Arabic examples are tested. The current app display defaults to
English. Unknown types, invalid definitions, inconsistent lengths, zero
divisors and nonfinite output retain raw bytes rather than copying
original exceptions or misleading zero defaults.

Current local status: **decoder implemented and verified for the retained
catalog; overall original inventory parity pending RE-02/RE-05**. No new ECU
writes, licensing changes, original-app execution, CI pass or hardware
compatibility is claimed. Targeted native table execution is recorded
separately from DEX source inference; hardware status remains `NOT_TESTED`.
