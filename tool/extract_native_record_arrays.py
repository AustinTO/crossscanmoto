"""Offline semicolon row arrays linked by ELF relative relocations.
Preserves header/array addresses. Does not infer an ECU owner from proximity.
"""
exec(open('tool/extract_native_pointer_tables.py').read().split('out=Path')[0])
import re
out=Path('assets/research/recovered-native/record-arrays');out.mkdir(parents=True,exist_ok=True)
def text(va):
 try:
  o=offset(va);e=b.index(b'\0',o)
  if e-o>50000:return None
  return b[o:e].decode('utf8')
 except (ValueError,UnicodeDecodeError):return None
arrays=[]
for slot,va in sorted(relocations.items()):
 header=text(va)
 if not header or ';' not in header or '\n' in header or not header.lower().startswith('id;'):continue
 fields=header.split(';');rows=[];at=slot+8
 while at in relocations:
  value=text(relocations[at])
  if value is None or ';' not in value or value.lower().startswith('id;'):break
  # Preserve literal rows; parser-specific trailing empty field behavior varies.
  if not re.match(r'^(?:0x[0-9a-fA-F]+|\d+);',value):break
  rows.append({'pointer_slot':hex(at),'text_address':hex(relocations[at]),'raw':value})
  at+=8
 if not rows:continue
 payload={'source_sha256':expected,'array_address':hex(slot),'header_address':hex(va),'header':fields,'rows':rows,'ecu_owner':None}
 name=f'{slot:x}.json';(out/name).write_text(json.dumps(payload,indent=2,ensure_ascii=False));arrays.append({'file':name,'array_address':hex(slot),'header':fields,'rows':len(rows)})
(out/'index.json').write_text(json.dumps(arrays,indent=2));print('Recovered',len(arrays),'candidate header-led row arrays with',sum(a['rows'] for a in arrays),'row occurrences')
for a in arrays[:8]:print(a['array_address'],a['rows'],a['header'][:7])
