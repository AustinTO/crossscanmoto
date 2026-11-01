"""Build a provenance-bearing data bundle from successful native table queries."""
import json
from pathlib import Path
root=Path('assets/research/recovered-native');index=json.loads((root/'runtime-tables-index.json').read_text());ecus={}
for item in index:
 if 'row_count' not in item:continue
 table=json.loads((root/'runtime-tables'/item['key']/(item['table']+'.json')).read_text())
 ecus.setdefault(item['key'],{})[item['table']]={'rows':table['rows'],'stdout_sha256':item['sha256']}
validation=json.loads((root/'runtime-extraction-validation.json').read_text())
bundle={'source_package':'de.wgsoft.motoscan','source_version':'1.110','native_sha256':validation['target_sha256'],'tables':ecus,'coverage':{'ecu_keys':len(ecus),'tables':validation['validated_nonempty_tables'],'rows':validation['validated_rows'],'failed_probes':validation['failed_probes']},'limitations':['Hardware compatibility not established by table recovery','Database protocol IDs are not Dart enum ordinals','Failed probes do not prove data absence']}
Path('assets/data/recovered_ecu_definitions.json').write_text(json.dumps(bundle,ensure_ascii=False,separators=(',',':')))
print(bundle['coverage'])
