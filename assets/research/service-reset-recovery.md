# MotoScan service-reset recovery

Source: supplied DEX disassembly in `/tmp/motoscan-disassembly.txt` from the supplied APK. The on-screen event names and command handlers are obfuscated, so this note cites DEX addresses and preserves original labels where recoverable.

## Inputs and event IDs

`dl0` enum initialization at `216390–2163dc` defines:

| Ordinal | Name | UI meaning established by call sites |
|---:|---|---|
| 0 | `SI_ALL` | Service reset submits the three writes in the handler |
| 1 | `SI_DATE` | Next-service date write |
| 2 | `SI_MILEAGE` | Next-service mileage write |
| 3 | `SI_DATE_CAR` | Vehicle/bike clock date and time write |

`ServiceData` (`px3.toString`, `4001dc–400224`) carries string fields `odometerValue`, `odometerUnits`, `vehicleDate`, `nextServiceDate`, and `nextServiceMileage`. The reset fragment (`sy3.onCreateView`, `401c28–401d54`) formats dates as `dd.MM.yyyy`, defaults the next service date to calendar date +365 days, and defaults the mileage field to `10000`. `ry3.onPreExecute` parses the field with `Integer.parseInt`; only `NumberFormatException` falls back to 10000 (`401b3c–401b66`). It captures `sy3.t1` as the next-service date, then `ry3.doInBackground` passes that date and `sy3.u1` (vehicle date) to the service handler (`401b24–401b28`, `4019a6–4019c6`).

## Confirmed UDS `sl0.C` write sequence

`sl0.C(Ldl0;I;Date;Date)` at `21fe78` implements the service-data UDS handler. It sends payloads through the currently attached `Lel0.h()`/`vq4.t()` adapter. The reset handler does not select an ECU address, enter diagnostic session, or perform security access itself; the ECU-specific `Lel0`/adapter selection must already be established by its caller.

The literal UDS `WriteDataByIdentifier` payloads and order are:

| Event | Payload | Data encoding |
|---|---|---|
| `SI_DATE_CAR` or `SI_ALL` | `2E E1 2B hh mm ss dd MM YYYYhi YYYYlo` | `hh/mm/ss` from the vehicle date argument; day, one-based month, and year big-endian follow |
| `SI_DATE` or `SI_ALL` | `2E E1 2C dd MM YYYYhi YYYYlo` | Day, one-based month, and year big-endian from the next-service date argument |
| `SI_MILEAGE` or `SI_ALL` | `2E E1 2D mileageHi mileageLo` | Low 16 bits of the parsed Java `int`, big-endian |

Evidence: the E12B buffer is allocated and populated at `21ff6a–21ffa2`; E12C at `22003a–220072`; E12D at `2200b4–2200f0`. `SI_ALL` takes the branches for all three in that order. Each transfer uses the existing adapter with a 2000 ms timeout and sleeps 1500 ms afterward (`21ff1e–21ff22`, `21ffae`, `21ffd4`, `220072`, `220098`, `2200f0`, `220116`). No UDS session-control (`0x10`) or security-access (`0x27`) request appears in this handler.

The original handler reads each transaction result but does not check a positive `0x6E` response or its DID; it finally constructs `Qx2(ERROR_OK, emptyBytes)` (`220126–220138`). `ry3.onPostExecute` therefore reports “Reset Ok” based on this result and then starts `q8` state refresh (`401a7c–401a9c`). The Dart implementation uses stricter positive-ack and readback checks so it cannot report success solely because a request was sent.

## Readback

The post-reset `q8` refresh calls `Lel0.r()` (`129e5c–129e88`). The `sl0.r()` implementation reads these identifiers in order:

1. `22 E1 19` — odometer; requires a seven-byte response and formats the integer at byte offset 3 (`21e018–21e0c8`).
2. `22 E1 2B` — vehicle date/time (`21e0cc–21e1b8`).
3. `22 E1 2D` — next-service mileage (`21e1b8–21e22c`).
4. `22 E1 2C` — next-service date; its static request bytes are `22 E1 2C` at `21e234–21e244`, with response formatting after that point.

All readbacks go through the active controller's same `vq4` instance. The exact factory-selected ECU/address is external to `sl0.r()`; this handler does not provide a safe default ECU address.

## Scope and unsupported handlers

This implementation exposes only the verified `sl0` UDS E12x profile and requires an already configured `UdsRequestLink`. It has no default target address. `Lll0` factory branches construct `sl0` descendants for labels including `cuX_ABS9M`, `cuX_ABS`, and `cuX_ABSVI` (`175e52–175f00`); other subclasses are built elsewhere in the same ECU factory. The recovered native ECU table is in `assets/research/recovered-native/ecu-groups.json`; relevant ABS groups include D_MRABS address 41, D_MRAABSN address 40, D_MRABS3 address 40, and G_MRABS address 41. Although the module names are related, the disassembly does not provide an authoritative one-to-one mapping from these native records to every `sl0` subtype. A caller must pass a selected ECU link and an explicit `sl0` profile; this API never infers a vehicle-to-target mapping.

### Feature gate binding

DEX `kl0` assigns ordinal 8 to `CF_SERVICE` (`2197bc–2197d2`). DEX `jl0(String)` parses the first semicolon-delimited field as that enum and sets its enabled flag from the second field being integer 1 (`2198d0–219972`). Runtime table rows live under `assets/research/recovered-native/runtime-tables/*/FUNCTIONS.json`; their evidence is offline native execution. The service reset API is gated only for exact keys whose row is `8;1;…` **and** whose DEX factory resolves to an `sl0` descendant:

| ECU key | `FUNCTIONS` row evidence | DEX handler binding |
|---|---|---|
| `cuX_BMSX` | `runtime-tables/cuX_BMSX/FUNCTIONS.json`: `8;1;0;0;0;0;49659` | Factory creates `f15`/`sl0` (`17571a–175726`) |
| `cuX_BMSE2B` | `runtime-tables/cuX_BMSE2B/FUNCTIONS.json`: `8;1;0;0;0;0;49659` | Factory creates `f15`/`sl0` (`17563c–175664`) |
| `cuX_BMSE2` | `runtime-tables/cuX_BMSE2/FUNCTIONS.json`: `8;1;0;0;0;0;49659` | Factory creates `i15`/`sl0` (`17566c–175694`) |
| `cuX_BMSMP1` | `runtime-tables/cuX_BMSMP1/FUNCTIONS.json`: `8;1;0;0;0;0;49659` | Factory creates `i15`/`sl0` (`1756cc–1756f4`) |
| `cuX_BMSO1` | `runtime-tables/cuX_BMSO1/FUNCTIONS.json`: `8;1;0;0;0;0;49659` | Factory creates `f15`/`sl0` (`1755d8–175602`) |

`cuMRBMSMP1` also has an enabled row in the extracted runtime table, but its DEX KWP controller is `jr` with `w=5`; `jr.C` falls through to `pl0.C`, which returns `ERROR_NOTSUPPORTED` for that value (`182538` switch dispatch, `21b2e0–21b316`). It is intentionally excluded from this UDS profile. K18/K46 KWP `qr`/`rr` reset handlers exist in DEX, but their recovered `FUNCTIONS` records do not enable category 8 and their protocol is not this UDS path.

The recovered runtime rows with category 8 explicitly disabled are `cuX_BMSMS1`, `cuX_AE`, `cuX_BMSTVS`, `cuX_BMSAE1`, and `cuX_ZES` (each `8;0;0;0;0;0;49659`). The runtime `cuX_KOMBI` table has no `8;…` record. These are not presented as supported service-reset targets.

Other handlers are not silently routed through this profile: `pl0.C` returns an empty `ERROR_NOTSUPPORTED` result (`21b2e0–21b316`); `nl0.C` and `er.C` do the same (`219d40–219d76`, `177c14–177c4a`); `il0.A` throws “Not yet implemented” (`2191e0–2191fe`). `qr.C` and `rr.C` are separate KWP variants that write local identifiers through `0x3B` templates `mc0.P/Q/R`; the factory uses these implementations for instrument-cluster labels including `MRKMB181`, `MRKOMB18`, `MRKMB461`, and `MRKOMB46` (`1762de–1763ca`). Their payloads and readback code are distinct from the UDS E12x handler and are not handled by this API. `jr.C` delegates to its `pl0` base for some model variants and contains separate variant-specific branches, so it is not considered supported generically.
