import json, subprocess
from pathlib import Path
root = Path(__file__).resolve().parent.parent
sdk = Path('/tmp/flutter-copy/cache/dart-sdk')
p = subprocess.Popen([str(sdk/'bin/dartaotruntime'), str(sdk/'bin/snapshots/analysis_server_aot.dart.snapshot'), '--cache=/tmp/motodiag-analysis'], stdin=subprocess.PIPE, stdout=subprocess.PIPE, text=True)
def send(i, method, params):
 p.stdin.write(json.dumps(dict(id=str(i), method=method, params=params))+'\n');p.stdin.flush()
send(1, 'server.setSubscriptions', {'subscriptions':['STATUS']})
send(2, 'analysis.setAnalysisRoots', {'included':[str(root/'lib'),str(root/'test')], 'excluded':[]})
errors={}; started=False
for line in p.stdout:
 event=json.loads(line)
 if event.get('event')=='analysis.errors': errors[event['params']['file']]=event['params']['errors']
 if event.get('event')=='server.status':
  active=event['params'].get('analysis',{}).get('isAnalyzing',False)
  if active: started=True
  if started and not active: break
for name, items in errors.items():
 for item in items: print(name, item['severity'], item['message'])
send(3,'server.shutdown',{})
p.wait(timeout=10)
raise SystemExit(any(e['severity']=='ERROR' for items in errors.values() for e in items))
