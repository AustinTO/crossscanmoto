# Biketune 1.9.1 write investigation

This is a bounded static inspection, not evidence that any command was run or
accepted by a motorcycle. It does not establish complete model, ECU, or write
coverage. The locally supplied base APK matches the installed base APK by
SHA-256 (`8ba30314faecaf3de401897f2a35fdeda2e1920cad5a7528a0ccfe28c645a218`).
The extracted `assets/index.android.bundle` is Hermes bytecode version 98,
SHA-256 `76fe78c25679348520e12e3bff97c5acda0966b2f2f0e221c833ec239698deb9`.
The locally generated disassembly used below has SHA-256
`260339fc1e976a3d061091763752056915ff76195b2e5e96cdf7944b32936630`.
Line numbers below refer to that disassembly; they are tool output locations,
not stable source-code line numbers.

## Observed code paths

- `Function<?anon_0_writeDataByIdentifier>` (line 2105365) constructs a byte
  array containing `0x2E`, the high and low DID bytes, and the supplied
  payload, then calls the UDS `request` method. After the request returns it
  checks that the response has at least three bytes and that bytes 1 and 2
  match the requested DID; failure constructs an error. The evidence excerpt
  does not alone establish how the request method validates a positive SID or
  handles timeouts and negative responses.
- `Function<?anon_0_writeDidByEcu>` (line 2103524) resolves
  `session.ecu(...)`, selects its `uds` object, and delegates to
  `writeDataByIdentifier`.
- `Function<?anon_0_writeCodingPage>` (line 2320845) calls
  `sendUdsByEcu` around a call to `writeDidByEcu`, passing the selected page's
  `register` and `bytes` to the latter. Its generator has error handling and
  cleanup paths. The two-byte request constants used for the surrounding calls
  have not been independently decoded here; do not infer their bytes from the
  function names.
- `Function<?anon_2_commitCodingPages>` (line 2321296) refers to
  `commitCodingTransaction`, `commitCps`, a BMW CPS DID and a CPS payload
  builder. The full transaction semantics and conditions remain to be traced.
  A separate `probeCodingAccess` path calls UDS and reads a DID; its complete
  state machine is also unresolved.
- A bundled user-facing string says each change writes one control-unit block
  and reads it back, and instructs the user to cycle the ignition. This is an
  application claim, not a dynamically verified transaction. Do not confuse the
  separately named `readBackMatches` function (line 2350611), which concerns a
  service-date cluster snapshot, with coding readback evidence.

## Catalog evidence and limitations

The Hermes string table contains SQL selecting `request_pdu`, `hold_pdu`,
`stop_pdu`, `positive_response`, `keepalive_ms`, `wait_ms` and `repeat` from
`service_steps`; a separate actuator query selects request and response fields.
Queries for coding functions select the CAFD root/version, register, bit range,
mask, default and series mask, and exclude disabled rows. Coding retrofit
queries also filter by CAFD version and type. These queries establish the
schema used by the shipped app, not the records or their applicability.

The package's `res/raw/assets_library_librarydb.enc` is encrypted. The app's
private database is inaccessible through ordinary `run-as` on the non-debuggable
installed build. This investigation has not recovered its rows, all operation
handlers, ECU security/session requirements, firmware applicability or a live
trace. The implementation of a single generic UDS write is not evidence that
all coding, service and actuator operations can be safely reproduced.
