# Merged baseline verification, 2026-11-02

The checkout initially reported `eccae2fb1d097fff0ee0f4fa2e8e74d2ce536845`.
After fetching origin and a fast-forward, HEAD is the supplied merged audit
commit `adf98d171d0c828e60e6d7cf6fbb4d06e87c9437`. There are no newer commits
in the fetched `origin/main`. The old `ceee4cbb` baseline must not be used to
infer which code changes remain open.

## Local execution

- `flutter test --no-pub --concurrency=1`: **99 passed**, including eight
  untracked RE-07 replay tests carried forward from the previous work.
  This run precedes the RE-09 decoder changes; their validation is separate.
- `cd backend/worker && node test/purchases.test.mjs`: **25 passed**.
  This executes the test module directly. In this environment `npm test`
  reported only one passing file-level test, so that summary is not used as
  evidence of 25 individually executed assertions.

The Flutter suite includes diagnostic target rebinding, service bounds,
actuator cleanup/cancellation, Garage state and source-specific KWP negative
responses. The backend suite includes authenticated sessions and store binding.
Passing these tests is local regression evidence, not original MotoScan parity.

## CI and hardware

Static review of `.github/workflows/apple-build.yml` confirms simulator and
unsigned iOS release jobs, plus a manually gated signed path requiring signing
configuration. No Apple build was executed locally on this Linux host.
The connected GitHub `fetch_commit_workflow_runs` query for this SHA returned
an empty list; its push-run filtering does not establish the status of all
PR/manual runs. CI status remains **unverified**, not passed.

No adapter or motorcycle validation was performed. Hardware state: `NOT_TESTED`.
No deployment, signing configuration, entitlement, or ECU-write logic changed.
