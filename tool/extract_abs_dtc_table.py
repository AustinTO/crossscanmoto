"""Recover cuMRABS TROUBLECODES, proven by factory and table dispatch assembly."""
exec(open('tool/extract_native_pointer_tables.py').read().split('out=Path')[0])
rows=[]
for i in range(27):
 slot=0x985d00+i*8;va=relocations[slot];start=offset(va);raw=b[start:b.index(b'\0',start)].decode('utf8');parts=raw.split(';')
 assert len(parts)==2 and all(p.isdigit() for p in parts)
 rows.append({'raw':raw,'code_decimal':int(parts[0]),'description_id':int(parts[1]),'pointer_address':hex(slot),'text_address':hex(va)})
output={'source_sha256':expected,'ecu_key':'cuMRABS','table':'TROUBLECODES','factory_address':'0x88e3d0','query_method':'0x892224','dispatch_check':'0x8923e4','array_address':'0x985d00','rows':rows,'limits':'Description IDs require separate localization lookup. Applicability to a particular bike requires the original ECU selection path.'}
Path('assets/research/recovered-native/cuMRABS-troublecodes.json').write_text(json.dumps(output,indent=2))
print('Recovered',len(rows),'cuMRABS troublecode/description-ID records')
