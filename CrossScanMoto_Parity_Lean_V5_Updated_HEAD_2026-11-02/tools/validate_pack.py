#!/usr/bin/env python3
"""Sanity-check scope, file integrity, updated ticket wording and source reference files."""
from pathlib import Path
import csv, json, re, sys
base=Path(__file__).resolve().parent.parent
issues=list(csv.DictReader((base/'reference'/'ISSUE_TRACKER.csv').open(encoding='utf8')))
assert len(issues)==47, f'Expected 47 issues, got {len(issues)}'
ids=[r['id'] for r in issues]
assert len(set(ids))==47
for r in issues:
    assert r['title'] and r['fix'] and r['acceptance'] and r['files']
    assert 'Create a virtual ELM/STN adapter and scriptable BMW ECU simulator' not in r['title'], r['id']
text=(base/'reference'/'01_FULL_CHECKLIST.md').read_text()
for id in ids:
    assert text.count(f'#### [ ] {id} |')==1,id
assert 'without a full adapter or ecu emulator' in (base/'04_OFFLINE_REPLAY_PLAN.md').read_text().lower()
assert 'No full virtual ELM/STN' in (base/'00_START_HERE.md').read_text()
for n in ['runtime_capability_contract','diagnosis_event_contract','ecu_key_reference_55','recovered_vehicle_reference_84','guided_playbooks_v3','source_registry_additions_v3','source_backed_claims_v3']:
    json.loads((base/'knowledge/data'/f'{n}.json').read_text())
print('VALID V4 PACK: 47 unique tickets, no required full emulator, checklist complete, JSON references parse.')
