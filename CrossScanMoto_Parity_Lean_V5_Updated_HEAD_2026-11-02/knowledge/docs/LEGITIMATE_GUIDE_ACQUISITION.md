# Legitimate data acquisition, authority, coverage and update process

## High-authority sources

- BMW Motorrad rider manuals: https://www.bmwmotorcycles.com/en/service/manuals/rider-manual.html. Resolve exact model, market, edition and options; maintain indexed topics: instrument alerts, technical data, pre-ride, maintenance, electrics and emergency guidance. Do not bulk rehost PDFs without permission.
- BMW Motorrad manuals and accessory instructions portal: https://www.bmwmotorcycles.com/en/service/manuals/service-overview.html.
- BMW service bulletins and manufacturer communications as published through NHTSA (for example K5x SIB 33 04 23). Match chassis, type code, VIN and revision; check new versions quarterly.
- BMW Motorrad recall VIN checker: https://nhtsa.bmwgroup.com/safetyrecall/pages/motorradRecallSearch.xhtml. Link out to current result, label time/region, and explain reported history exclusions. NHTSA alternative: https://www.nhtsa.gov/recalls.
- BMW Motorrad service information for qualified repairers may be available through licensed aftersales systems. Do not assume US BMW automotive TIS contains Motorrad repair instructions; current US TIS help excludes motorcycle repair information.

## Useful third-party but non-authoritative

- MotoScan own documentation for protocol exceptions and the existence of service routines: https://www.motoscan.de/docs/allgemein/unterstuetzte-motorraeder/. Benchmark, not proof this app supports the action.
- HEX GS-911 functionality chart: https://www.hexgs911.com/function-chart/. Benchmark, not a CrossScanMoto coverage matrix.
- OBDLink support for hardware compatibility: https://support.obdlink.com/support/solutions/articles/43000713351.

## Rights and ingestion

Store citation metadata, cross-references, authored summaries, limited factual entries, issue date, update timestamp, applicability and confidence. Link full manuals externally; do not ship protected full texts, proprietary disassembly or third-party calibration command datasets as subscription content absent rights clearance. Keep two indexes: `guide_claim` and `app_capability`; never auto-promote one from the other.

## Freshness cadence

Monthly check for recalls/active bulletins and source link validity, quarterly for manual additions/model variants, on every Git commit for catalog differences, after every hardware test for capability state. Preserve previous editions and revalidate rules with newer source documents. Every response cites a source ID and states if the exact VIN/ECU match is unresolved.
