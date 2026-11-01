"""Extract contiguous pointer tables whose first row is explicit column names.
ECU ownership and wire semantics are intentionally unresolved.
"""
exec(open('tool/extract_native_pointer_tables.py').read().split('out=Path')[0])
import re
out=Path('assets/research/recovered-native/column-tables');out.mkdir(parents=True,exist_ok=True)
cache={}
def text(va):
 if va in cache:return cache[va]
 try:
  o=offset(va);e=b.index(b'\0',o);v=b[o:e].decode('utf8') if e-o<50000 else None
 except (ValueError,UnicodeDecodeError):v=None
 cache[va]=v;return v
index=[]
for base,va in sorted(relocations.items()):
 if text(va)!='id':continue
 headers=[];at=base
 while at in relocations and len(headers)<50:
  value=text(relocations[at])
  if not value or not re.fullmatch(r'[a-zA-Z_][a-zA-Z0-9_]*',value):break
  headers.append(value);at+=8
 if len(headers)<2 or len(headers)==50:continue
 rows=[]
 while len(rows)<20000:
  start=at
  raw=[]
  for field in headers:
   if at not in relocations:break
   value=text(relocations[at])
   if value is None:break
   raw.append(value);at+=8
  if len(raw)!=len(headers) or not re.fullmatch(r'\d+',raw[0]):break
  rows.append(raw)
 if not rows:continue
 name=f'{base:x}.json';(out/name).write_text(json.dumps({'source_sha256':expected,'array_address':hex(base),'headers':headers,'rows':rows,'ecu_owner':None},indent=2,ensure_ascii=False))
 index.append({'file':name,'address':hex(base),'headers':headers,'rows':len(rows),'limit_reached':len(rows)==20000})
(out/'index.json').write_text(json.dumps(index,indent=2));print(len(index),'candidate tables;',sum(t['rows'] for t in index),'row occurrences')
for t in index[:12]:print(t['address'],t['rows'],t['headers'][:8])
