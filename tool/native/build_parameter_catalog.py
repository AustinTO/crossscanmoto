"""Compile only observed UDS 0x22 read requests from recovered native rows."""
import json
from pathlib import Path
root=Path('assets/research/recovered-native/runtime-tables');catalog={}
texts={r['id']:r['text'] for line in Path('assets/research/recovered-native/localized-texts.ndjson').read_text().splitlines() if (r:=json.loads(line))['method']=='t'}
for table in sorted(root.glob('*/PARAMS.json')):
 data=json.loads(table.read_text());rows=[]
 for raw in data['rows']:
  fields=raw.split(';')
  if len(fields)<3:continue
  try:request=[int(value,16) for value in fields[1].split(',')]
  except ValueError:continue
  if len(request)!=3 or request[0]!=0x22 or any(v<0 or v>255 for v in request):continue
  rows.append({'id':fields[0],'name':fields[2],'did':(request[1]<<8)|request[2],'raw':raw,'label':texts.get(int(fields[5]),fields[2]) if len(fields)>5 and fields[5].isdigit() else fields[2]})
 if rows:catalog[data['ecu_key']]=rows
out=Path('assets/data');out.mkdir(parents=True,exist_ok=True)
(out/'recovered_uds_parameters.json').write_text(json.dumps(catalog,ensure_ascii=False,indent=2))
print('Compiled',sum(map(len,catalog.values())),'observed read requests across',len(catalog),'ECU definitions')
