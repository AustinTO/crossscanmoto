"""Compile observed UDS read requests and ECU-scoped native result metadata.

PARAMS_RES parent and PARAMS_TAB result joins use the numeric keys recovered
from the original parsers. Unavailable/global value-list rows are not guessed.
"""
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
TABLE_ROOT = ROOT / 'assets/research/recovered-native/runtime-tables'
TEXTS = ROOT / 'assets/research/recovered-native/localized-texts.ndjson'
UNITS = ROOT / 'assets/research/recovered-native/units-runtime.txt'
TEXT_PROBES = ROOT / 'assets/research/recovered-native/re09-tab-text-reprobes.json'
OUTPUT = ROOT / 'assets/data/recovered_uds_parameters.json'


def load_table(folder, name):
    path = folder / f'{name}.json'
    if not path.exists():
        return []
    return json.loads(path.read_text())['rows']


def int_field(row, index):
    fields = row.split(';')
    if len(fields) <= index:
        return None
    value = fields[index].strip()
    sign = -1 if value.startswith('-') else 1
    if value[:1] in ('+', '-'):
        value = value[1:]
    base = 10
    if value.startswith(('0x', '0X')):
        base, value = 16, value[2:]
    elif value.startswith('#'):
        base, value = 16, value[1:]
    elif len(value) > 1 and value.startswith('0'):
        base, value = 8, value[1:]
    try:
        return sign * int(value, base)
    except ValueError:
        return None


def compile_catalog(table_root=TABLE_ROOT, texts_path=TEXTS, units_path=UNITS):
    texts = {}
    for line in texts_path.read_text().splitlines():
        record = json.loads(line)
        if record.get('method') == 't':
            texts[record['id']] = (record['text'], 'native_t')

    if TEXT_PROBES.exists():
        probe_data = json.loads(TEXT_PROBES.read_text(encoding='utf-8'))
        for record in probe_data.get('results', []):
            if record.get('exit_code') != 0:
                continue
            method_values = {}
            for line in record.get('stdout', '').splitlines():
                method, separator, value = line.partition('\t')
                if separator:
                    method_values[method] = value
            if 't' not in method_values:
                continue
            value = method_values['t']
            source = 'native_placeholder' if value == 'unknown text' else 'native_t_probe'
            texts.setdefault(record['id'], (value, source))

    general_values = {}
    if units_path.exists():
        for raw in units_path.read_text(encoding='utf-8').splitlines()[1:]:
            fields = raw.split(';')
            if len(fields) < 2:
                continue
            try:
                general_values[int(fields[0], 10)] = fields[1]
            except ValueError:
                continue

    catalog = {}
    for params_path in sorted(table_root.glob('*/PARAMS.json')):
        folder = params_path.parent
        params = json.loads(params_path.read_text())
        ecu = params['ecu_key']
        results = load_table(folder, 'PARAMS_RES')
        tabs = load_table(folder, 'PARAMS_TAB')
        result_by_parent = {}
        for raw in results:
            parent = int_field(raw, 1)
            if parent is not None:
                result_by_parent.setdefault(parent, []).append(raw)

        # Ll21.<init> decodes token 1 into ljw.a; the loader compares it to
        # k21.a (PARAMS_RES token 0), as recovered at DEX 0x217b94-0x217bae.
        tabs_by_result = {}
        for raw in tabs:
            result_id = int_field(raw, 1)
            if result_id is not None:
                tabs_by_result.setdefault(result_id, []).append(raw)

        rows = []
        for raw in params['rows']:
            fields = raw.split(';')
            if len(fields) < 3:
                continue
            try:
                request = [int(value, 16) for value in fields[1].split(',')]
            except ValueError:
                continue
            if len(request) != 3 or request[0] != 0x22 or any(v < 0 or v > 255 for v in request):
                continue
            parent = int_field(raw, 0)
            parameter_label = (
                texts.get(int(fields[5]), (fields[2], 'raw_name'))[0]
                if len(fields) > 5 and fields[5].isdigit()
                else fields[2]
            )
            result_records = []
            for result in result_by_parent.get(parent, []):
                result_id = int_field(result, 0)
                matching_tabs = tabs_by_result.get(result_id, [])
                value_id = int_field(result, 4)
                result_label_id = int_field(result, 14)
                tab_values = []
                for tab_raw in matching_tabs:
                    tab_value_id = int_field(tab_raw, 3)
                    tab_text = texts.get(tab_value_id) if tab_value_id is not None else None
                    tab_values.append({
                        'raw': tab_raw,
                        'text_id': tab_value_id,
                        'text': tab_text[0] if tab_text is not None else None,
                        'text_source': tab_text[1] if tab_text is not None else 'unresolved',
                    })
                general_value = general_values.get(value_id)
                result_label = texts.get(result_label_id)
                result_records.append({
                    'raw': result,
                    'label_id': result_label_id,
                    'label': result_label[0] if result_label is not None else parameter_label,
                    'label_source': result_label[1] if result_label is not None else 'parameter_fallback',
                    'unit_id': value_id,
                    'unit': '' if matching_tabs or general_value in (None, '-') else general_value,
                    'tabs': tab_values,
                })
            rows.append({
                'id': fields[0], 'name': fields[2],
                'did': (request[1] << 8) | request[2], 'raw': raw,
                'label': parameter_label,
                'results': result_records,
            })
        if rows:
            catalog[ecu] = rows
    return catalog


def main():
    catalog = compile_catalog()
    OUTPUT.write_text(json.dumps(catalog, ensure_ascii=False, indent=2) + '\n')
    print('Compiled', sum(map(len, catalog.values())), 'observed read requests across', len(catalog), 'ECU definitions')


if __name__ == '__main__':
    main()
