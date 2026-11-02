# P0-05: legacy service handler source evidence

This note records handler bodies and request construction from MotoScan 1.110
`classes.dex`. It does not bind these classes to ECU keys; that mapping is
tracked in the companion factory/controller evidence. Focused DEX excerpts are
in [`fixtures/P0-05-legacy-service-excerpts.txt`](fixtures/P0-05-legacy-service-excerpts.txt).

## Artifact and operation gate

MotoScan 1.110 APK SHA-256:
`bfc07ce264a0c35df9d63558f4fa64c4bd3dd845903d3e0417532250ea0e7e58`.
DEX SHA-256:
`869025551e5339811c300f2ae5ec92563c7e6b228d9498b8e835e2ac79283832`.

The operation category gate is FUNCTIONS token 0 = **12 (`CF_SERVICE`)**;
token 0 = **8 (`CF_ADAPTIONS`)** is a separate category. See the source-backed
category mapping in [RE-02-routing-evidence.md](RE-02-routing-evidence.md).
This note does not infer keybindings from labels or action names.

## Legacy KWP handlers `qr.C` and `rr.C`

Both method bodies send the same mutable `mc0.P/Q/R` templates. `b00.n(int...)`
casts the listed integers to bytes without adding a frame header or checksum:

| Template | Initial bytes | Fields filled by handler |
|---|---|---|
| P | `3B 10 00 00 00 00 00 00 00` | indices 2–8: default-time-zone `Calendar` hour, minute, second, day, month (1-based), year high byte, year low byte |
| Q | `3B 11 00 00 00 00` | indices 2–5: day, month (1-based), year high byte, year low byte from the supplied `date` |
| R | `3B 12 00 00` | indices 2–3: `(mileage >> 8) & 0xff`, `mileage & 0xff` |

The enum is `dl0`: `SI_ALL` ordinal 0, `SI_DATE` 1, `SI_MILEAGE` 2,
`SI_DATE_CAR` 3. Both handlers use this fixed order:

1. For `SI_DATE_CAR` or `SI_ALL`, send P using `date2`.
2. For `SI_DATE` or `SI_ALL`, send Q using `date`.
3. For `SI_MILEAGE` or `SI_ALL`, send R using the low 16 bits of the integer argument.

`qr.C` is at DEX `0x197624`; it has no constructor selector and calls
`vq4.s(template, 3000)` for each enabled operation. `rr.C` is at `0x1987f4`;
its constructor stores integer selector `w` (`rr.<init>(I)` at `0x19a11c`).
The C-method switch at `0x198858` has a case for selector 0 and a default
branch; both bodies produce the same three requests and use the same gates.
The default is not an unsupported return path. Other `rr` overrides branch on
`w`, but no per-key selector assignment is asserted here.

The handlers inspect only the first returned wrapper's byte-array length when
a response exists; the length is assigned to an unused local. They do not
validate a positive ACK, read data back, or condition later writes on ACK
content. After all enabled writes they return `qx2(ERROR_OK, empty bytes)`.
There is no pre-read or cleanup frame in either C body. `qr.C` checks its enum
and both date arguments for null before dispatch. `rr.C` dereferences `date2`
before dispatch; it uses `date` only for SI_DATE/SI_ALL.

`rr.S()` is a separate variant-identification hook, not a pre-read embedded
inside `rr.C`. With selector 0 it calls `rr.p0()`; every nonzero selector calls
`rr.q0()`, and the method returns `true` either way. Both hooks read
`mc0.Z0 = 22 30 0A` (ReadDataByIdentifier DID `0x300A`), require a response
longer than three bytes with byte 0 `0x62`, and map response byte 3 to a
displayed vehicle variant. Their request timeout differs: 1000 ms for `p0`,
3000 ms for `q0`. `qr` has no `S()` override and inherits `pl0.S()`, which
returns true without a read. This handler evidence does not establish whether
the UI lifecycle invokes `rr.S()` before calling `C`.

## Shared UDS service operation `sl0.C`

`sl0.C(dl0,int,Date,Date)` at DEX `0x21fe78` builds direct UDS
WriteDataByIdentifier payloads (service `0x2e`, DID `0xe12b`); this path is
separate from the legacy KWP `0x3b` handlers above:

| Enabled event | Payload | Source values |
|---|---|---|
| SI_DATE_CAR or SI_ALL | `2E E1 2B hh mm ss dd MM yyyy_hi yyyy_lo` (10 bytes) | `date2`; hour/minute/second, day, 1-based month, 16-bit year, big-endian |
| SI_DATE or SI_ALL | `2E E1 2C dd MM yyyy_hi yyyy_lo` (7 bytes) | `date`; day, 1-based month, 16-bit year, big-endian |
| SI_MILEAGE or SI_ALL | `2E E1 2D mileage_hi mileage_lo` (5 bytes) | low 16 bits of the integer argument, big-endian; no unit conversion in this method |

The enabled operations run in the same P/date-car, Q/date, R/mileage order.
Each uses `vq4.t(payload, 2000, -1)`, inspects but does not validate the first
response data length, then sleeps 1500 ms. The sleep follows each enabled
operation. The method returns `qx2(ERROR_OK, empty bytes)` regardless of the
response wrapper contents; no readback or separate cleanup request appears in
this method. It eagerly checks the enum and both Date arguments for null even
when the selected event does not use both dates.

MotoScan 1.83 cross-check: `n2.e.Y` at DEX `0x26798c` has the same four event
values, byte layouts, argument/date mapping, 2000 ms request timeout,
1500 ms inter-operation sleeps, and `ERROR_OK` empty-body result. Its base
`n2.c.Y` returns `ERROR_NOTSUPPORTED`. This confirms the shared UDS body across
these versions. No directly corresponding 1.83 legacy KWP `0x3b` handler was
established in this focused trace.

## Adapter response and transport boundary

`vq4.s(bytes, timeout)` delegates to `vq4.t(bytes, timeout, -1)`. `vq4.t`
converts the request bytes to contiguous uppercase hex and calls `vq4.r`; `r`
writes that text followed by carriage return to the selected adapter stream.
This evidence identifies the adapter command bytes, not ISO-TP/CAN wire
framing.

For a returned response beginning `7f`, `vq4.t` recursively resends the same
request for NRC `0x21`; for NRC `0x78`, it drops consecutive pending frames and
returns the first following frame if one exists; other negative responses are
wrapped as `ERROR_7F`. No response becomes `ERROR_UNKNOWN` with empty bytes;
otherwise the first decoded response is wrapped as `ERROR_OK`. `qr.C`, `rr.C`
and `sl0.C` discard this status/body distinction after reading the byte-array
length and still return their own `ERROR_OK` empty result. Thus the service
methods do not expose adapter/ECU ACK outcome to their caller.
The visible NRC-`0x21` path recursively resends without a counter or delay; no
retry bound is visible in this method.

## Scope and remaining mapping

The KWP and UDS request templates, event selection, order, byte offsets,
timeouts, and method-level ACK/readback behavior above are directly supported
by the DEX. The ECU-group/controller-to-class and constructor-selector mapping
is a separate source lane; these class bodies alone do not establish which
vehicle/ECU key invokes each handler. No app execution, adapter exchange, or
vehicle behavior is claimed.
