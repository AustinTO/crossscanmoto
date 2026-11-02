#!/usr/bin/env python3
"""Generate a small, targeted task context packet from ISSUE_TRACKER.csv.

Usage:
 python tools/task_packet.py --list
 python tools/task_packet.py --id RE-09
 python tools/task_packet.py --id P0-02 --json
 python tools/task_packet.py --track 'Protocol'

Runs with Python stdlib only. It never reads entire source files or binary artifacts.
"""
import argparse, csv, json
from pathlib import Path

BASE = Path(__file__).resolve().parent.parent
ISSUES = BASE / 'reference' / 'ISSUE_TRACKER.csv'
RELATED = {
    'RE-01': [],
    'RE-02': ['RE-01'],
    'RE-03': ['RE-01', 'RE-07'],
    'RE-04': ['RE-01', 'RE-07'],
    'RE-05': ['RE-01'],
    'RE-06': ['RE-01'],
    'RE-07': ['RE-01'],
    'RE-08': ['RE-02', 'RE-05'],
    'RE-09': ['RE-05', 'RE-07'],
    'RE-10': ['RE-04', 'RE-05', 'RE-07'],
    'RE-11': ['RE-05', 'RE-07'],
    'P0-01': ['RE-02'],
    'P0-02': ['RE-02', 'RE-11'],
    'P0-03': ['RE-11'],
}

def issues():
    with ISSUES.open(newline='', encoding='utf-8-sig') as f:
        return list(csv.DictReader(f))

def main():
    p=argparse.ArgumentParser(description=__doc__)
    g=p.add_mutually_exclusive_group(required=True)
    g.add_argument('--list', action='store_true', help='Brief ticket list')
    g.add_argument('--id', help='One ticket (e.g. RE-09)')
    g.add_argument('--track', help='Filter a workstream by track name')
    p.add_argument('--json', action='store_true')
    a=p.parse_args()
    rows=issues()
    if a.list:
        print('\n'.join(f"{r['id']:7} {r['priority']:2} {r.get('audit_status','open'):23.23} {r['title']}" for r in rows))
        return
    if a.track:
        for r in rows:
            if a.track.lower() in r['track'].lower():
                print(f"{r['id']:7} {r['priority']:2} {r['title']}")
        return
    r=next((x for x in rows if x['id'].lower()==a.id.lower()),None)
    if not r:
        p.error(f'Unknown ticket {a.id}. Run --list.')
    packet={
        'id':r['id'], 'priority':r['priority'], 'track':r['track'],
        'title':r['title'],
        'audit_status':r.get('audit_status','open_unverified'),
        'merged_evidence':r.get('merged_evidence',''),
        'next_action':r.get('next_action',''),
        'files': [x.strip() for x in r['files'].split(';') if x.strip()],
        'required_action':r['fix'], 'acceptance':r['acceptance'],
        'related_tickets_review_only':RELATED.get(r['id'],[]),
        'rules':'Read only scoped files. Use original-derived goldens with strict scripted link/transport fakes, NOT a full adapter/ECU emulator. No self-oracle or physical fleet prerequisite. Document scoped ECU writes.'
    }
    if a.json:
        print(json.dumps(packet,indent=2,ensure_ascii=False))
        return
    print(f"# {packet['id']} | {packet['priority']} | {packet['title']}\n")
    print(f"Track: {packet['track']}\nAudit status: {packet['audit_status']}\nMerged evidence: {packet['merged_evidence']}\nNext action: {packet['next_action']}\n")
    print('Files: ' + ', '.join(packet['files']))
    if packet['related_tickets_review_only']:
        print('Related tickets (review dependencies, do not load in full): '+ ', '.join(packet['related_tickets_review_only']))
    print('\nOriginal full-scope task (use status and next action above to avoid duplicate implementation): '+packet['required_action'])
    print('\nAcceptance: '+packet['acceptance'])
    print('\nRules: '+packet['rules'])
    print('\nDeliver: if code already merged, focused verification + gaps only; otherwise a minimal patch, independently sourced fixtures, tests, brief checkpoint. No full emulator.')

if __name__ == '__main__':
    main()
