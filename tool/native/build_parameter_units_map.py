"""Join recovered RESULT general-value ids to native display strings."""
import hashlib
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
NATIVE = ROOT / 'assets/research/recovered-native'
TABLES = NATIVE / 'runtime-tables'
UNITS = NATIVE / 'units-runtime.txt'
OUTPUT = NATIVE / 'parameter-general-value-associations.json'


def main():
    units = {}
    for raw in UNITS.read_text(encoding='utf-8').splitlines()[1:]:
        fields = raw.split(';')
        if len(fields) < 2:
            continue
        try:
            units[int(fields[0], 10)] = fields[1]
        except ValueError:
            continue

    associations = []
    missing = []
    source_hashes = {}
    for path in sorted(TABLES.glob('*/PARAMS_RES.json')):
        table = json.loads(path.read_text(encoding='utf-8'))
        ecu = table['ecu_key']
        source_hashes[ecu] = table['sha256']
        for raw in table['rows']:
            fields = raw.split(';')
            if len(fields) <= 4:
                missing.append({'ecu_key': ecu, 'raw': raw, 'reason': 'short PARAMS_RES row'})
                continue
            try:
                result_id, parent_id, unit_id = int(fields[0]), int(fields[1]), int(fields[4])
            except ValueError:
                missing.append({'ecu_key': ecu, 'raw': raw, 'reason': 'unparsed numeric key'})
                continue
            unit = units.get(unit_id)
            if unit is None:
                missing.append({'ecu_key': ecu, 'raw': raw, 'reason': f'no GENERAL_VALUES_UNITS id {unit_id}'})
                continue
            associations.append({
                'ecu_key': ecu,
                'result_id': result_id,
                'parameter_id': parent_id,
                'name': fields[2],
                'general_value_id': unit_id,
                'display_text': unit,
                'raw': raw,
            })

    units_bytes = UNITS.read_bytes()
    output = {
        'evidence_type': 'DEX-backed numeric key join over recovered native table rows',
        'source': {
            'units_table': str(UNITS.relative_to(ROOT)),
            'units_table_sha256': hashlib.sha256(units_bytes).hexdigest(),
            'result_table_sha256_by_ecu': source_hashes,
            'dex_evidence': 'fl0.g at 0x217bf6-0x217c12 compares nq4.a with k21.e and assigns nq4.b to k21.s; nq4 parser at 0x468f58 stores tokens 0 and 1 and does not retain token 2.',
            'semantic_limit': 'The result-to-GENERAL_VALUES_UNITS string association is proven; this does not prove that every display string is a physical measurement unit.',
        },
        'general_values_by_id': {str(key): value for key, value in sorted(units.items())},
        'association_count': len(associations),
        'unresolved_count': len(missing),
        'associations': associations,
        'unresolved': missing,
    }
    OUTPUT.write_text(json.dumps(output, ensure_ascii=False, indent=2) + '\n')
    print(f'Wrote {len(associations)} general-value associations; {len(missing)} unresolved rows')


if __name__ == '__main__':
    main()
