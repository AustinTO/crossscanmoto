"""Generate ECU-scoped descriptions from original tables and native accessor v."""
import collections,json
from pathlib import Path
source=Path('assets/research/recovered-native')
texts={r['id']:r['text'] for line in (source/'localized-texts.ndjson').read_text().splitlines() if (r:=json.loads(line))['method']=='v'}
per={};codes=collections.defaultdict(set)
for file in sorted((source/'runtime-tables').glob('*/TROUBLECODES.json')):
 data=json.loads(file.read_text());values={}
 for row in data['rows']:
  fields=row.split(';')
  if len(fields)<2 or not fields[0].isdigit() or not fields[1].isdigit():continue
  code,label=int(fields[0]),texts.get(int(fields[1]))
  if label:values[code]=label;codes[code].add(label)
 if values:per[data['ecu_key']]=values
unique={code:next(iter(labels)) for code,labels in codes.items() if len(labels)==1}
def quote(value):return json.dumps(value,ensure_ascii=True).replace('$','\\$')
output='// Generated original ECU-scoped fault text; see tool/native/build_dtc_catalog.py.\nabstract final class RecoveredDtcDescriptions {\n  static const byEcu = <String, Map<int,String>>{\n'
for key,values in per.items():output+=quote(key)+':{'+','.join(f'{code}:{quote(label)}' for code,label in values.items())+'},\n'
output+='};\nstatic const unambiguous=<int,String>{'+','.join(f'{code}:{quote(label)}' for code,label in unique.items())+'};\n}\n'
Path('lib/diagnostics/recovered_dtc_descriptions.dart').write_text(output)
print(f'Generated {sum(map(len,per.values()))} ECU-scoped fault descriptions; {len(codes)-len(unique)} ambiguous codes require an ECU key')
