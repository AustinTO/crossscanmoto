"""Recover the exact MotoScan 1.110 arm64 static table copied at 0x6fb7e0.
No target execution. Field roles remain unassigned until query callers prove them.
"""
import hashlib,json,struct,sys
from pathlib import Path
source=Path(sys.argv[1] if len(sys.argv)>1 else '/tmp/motoscan.so')
b=source.read_bytes()
expected='bab0c173bb33c37262d07bbbbdc2c91213275d2a68e941d1b39fc3affd34fc71'
assert hashlib.sha256(b).hexdigest()==expected,'Unsupported artifact identity'
phoff=struct.unpack_from('<Q',b,32)[0]; phsize,phcount=struct.unpack_from('<HH',b,54)
segments=[struct.unpack_from('<IIQQQQQQ',b,phoff+i*phsize) for i in range(phcount)]
def offset(va):
 for p in segments:
  if p[0]==1 and p[3]<=va<p[3]+p[5]: return p[2]+va-p[3]
 raise ValueError(hex(va))
shoff=struct.unpack_from('<Q',b,40)[0]; shsize,shcount=struct.unpack_from('<HH',b,58)
relocations={}
for i in range(shcount):
 sh=struct.unpack_from('<IIQQQQIIQQ',b,shoff+i*shsize)
 if sh[1]!=4:continue
 for at in range(sh[4],sh[4]+sh[5],sh[9]):
  va,info,addend=struct.unpack_from('<QQq',b,at)
  if info&0xffffffff==1027:relocations[va]=addend
out=Path('assets/research/recovered-native');(out/'blobs').mkdir(parents=True,exist_ok=True)
records=[];blobs={}
for record in range(85):
 fields=[]
 for field in range(13):
  slot=0x9144e8+record*104+field*8
  va=relocations.get(slot)
  if va is None:
   fields.append({'slot':hex(slot),'raw':struct.unpack_from('<Q',b,offset(slot))[0]});continue
  start=offset(va);end=b.index(b'\x00',start);raw=b[start:end]
  digest=hashlib.sha256(raw).hexdigest()
  (out/'blobs'/f'{digest}.txt').write_bytes(raw)
  blobs[digest]=len(raw)
  fields.append({'slot':hex(slot),'address':hex(va),'sha256':digest,'bytes':len(raw),'preview':raw[:100].decode('utf8','replace')})
 records.append({'record':record,'fields':fields})
(out/'index.json').write_text(json.dumps({'source_sha256':expected,'constructor':'0x6fb7e0','table_address':'0x9144e8','record_stride':104,'records':records,'unique_blobs':blobs},indent=2))
print('Recovered',len(records),'records;',len(blobs),'unique text blobs;',sum(blobs.values()),'bytes')
for r in records[:8]: print(r['record'],[(f.get('preview','')[:65]) for f in r['fields'][:3]])
# Additional blocks copied by the same constructor. Header strings establish
# field boundaries; sizes/strides checked against constructor memcpy lengths.
for name,base,size,fields in [
 ('series',0x914368,384,6),
 ('platform-ecu-groups',0x916770,800,2),
 ('ecu-groups',0x916a90,1920,8),
]:
 assert size%(fields*8)==0
 table=[]
 for row in range(size//(fields*8)):
  values=[]
  for field in range(fields):
   slot=base+(row*fields+field)*8;va=relocations[slot];start=offset(va)
   values.append(b[start:b.index(b'\x00',start)].decode('utf8'))
  table.append(values)
 headers=table[0]
 (out/f'{name}.json').write_text(json.dumps({'source_sha256':expected,'table_address':hex(base),'headers':headers,'records':[dict(zip(headers,row)) for row in table[1:]]},indent=2))
 print(name,len(table)-1,'records')
# Emit exact decoded vehicle rows reproducibly, using the first record's headers.
headers=[(out/'blobs'/f"{field['sha256']}.txt").read_text() for field in records[0]['fields']]
vehicle_rows=[]
for record in records[1:]:
 vehicle_rows.append(dict(zip(headers,[(out/'blobs'/f"{field['sha256']}.txt").read_text() for field in record['fields']])))
(out/'vehicle-records.json').write_text(json.dumps(vehicle_rows,indent=2))
