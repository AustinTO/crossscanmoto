"""Bounded offline native-table probes using the supplied library under QEMU.
Candidate names are hypotheses; only nonempty returned tables are retained.
"""
import json,subprocess,hashlib
from pathlib import Path
assert hashlib.sha256(Path('/tmp/motoscan.so').read_bytes()).hexdigest()=='bab0c173bb33c37262d07bbbbdc2c91213275d2a68e941d1b39fc3affd34fc71'
root=Path('assets/research/recovered-native');groups=json.loads((root/'ecu-groups.json').read_text())['records']
keys=json.loads((root/'observed-ecu-keys.json').read_text())
tables=['PARAMS','PARAMS_RES','PARAMS_TAB','PARAMS_TAB_GLOBAL','ACTUATOR','ACTUATORPOS','ACTUATORCMD','TROUBLECODES','FUNCTIONS','IDENTIFICATIONS']
results=[]
for key in keys:
 for table in tables:
  command=['prlimit','--cpu=5','--as=1073741824','qemu-aarch64','-L','/usr/aarch64-linux-gnu','/tmp/motoscan-table-probe','/tmp/motoscan.so',key,table]
  run=subprocess.run(command,capture_output=True,timeout=10)
  if run.returncode: results.append({'key':key,'table':table,'exit_code':run.returncode,'error':run.stderr.decode(errors='replace')[:300]});continue
  rows=run.stdout.decode('utf8').splitlines()
  if not rows:continue
  destination=root/'runtime-tables'/key;destination.mkdir(parents=True,exist_ok=True)
  payload={'ecu_key':key,'table':table,'rows':rows,'sha256':hashlib.sha256(run.stdout).hexdigest(),'evidence_type':'controlled offline native function execution; custom ELF loader under QEMU','limits':'ECU key observed in DEX literals; nonempty native query return is observed. No motorcycle or app network execution.'}
  (destination/f'{table}.json').write_text(json.dumps(payload,ensure_ascii=False,indent=2));results.append({'key':key,'table':table,'row_count':len(rows),'sha256':payload['sha256']})
(root/'runtime-tables-index.json').write_text(json.dumps(results,indent=2));print('Retained',sum('row_count'in r for r in results),'nonempty tables;',sum(r.get('row_count',0) for r in results),'rows;',sum('exit_code'in r for r in results),'failed probes')
