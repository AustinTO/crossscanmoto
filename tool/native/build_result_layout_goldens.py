"""Build independent STATIC_GOLDEN vectors for non-NUMBER PARAMS_RES rows.

Inputs are recovered original table rows and localized TAB text. Expected bytes
and displays are computed from the RE-09 DEX description here, without loading
or executing the Dart implementation.
"""
import hashlib
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
CATALOG = ROOT / 'assets/data/recovered_uds_parameters.json'
TABLES = ROOT / 'assets/research/recovered-native/runtime-tables'
UNITS = ROOT / 'assets/research/recovered-native/general-values-units.json'
OUTPUT = ROOT / 'test/fixtures/params_result_layout_goldens.json'
DEX_SHA256 = '869025551e5339811c300f2ae5ec92563c7e6b228d9498b8e835e2ac79283832'
TYPES = {
    'unsigned char': (1, False),
    'signed char': (1, False),  # DEX dispatch quirk
    'char': (1, True),
    'unsigned int': (2, False),
    'int': (2, True),
    'signed int': (2, True),
    'unsigned long': (4, False),
}


def sha256(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def decode_int(token):
    """Java Integer.decode semantics for recovered table tokens."""
    text = token.strip()
    sign = 1
    if text.startswith(('+', '-')):
        sign = -1 if text[0] == '-' else 1
        text = text[1:]
    radix = 10
    if text.startswith(('0x', '0X')):
        radix, text = 16, text[2:]
    elif text.startswith('#'):
        radix, text = 16, text[1:]
    elif len(text) > 1 and text.startswith('0'):
        radix, text = 8, text[1:]
    return sign * int(text, radix)


def encoded_bytes(value, width):
    return (value & ((1 << (width * 8)) - 1)).to_bytes(width, 'big')


def raw_bytes(value, result_fields):
    width, _signed = TYPES[result_fields[6]]
    declared = int(result_fields[8])
    if width != declared:
        raise AssertionError(('unsupported tab-result width', result_fields[0], width, declared))
    return encoded_bytes(value, width)


def c_value(bytes_, c_type):
    width, signed = TYPES[c_type]
    value = int.from_bytes(bytes_, 'big', signed=False)
    if signed and value & (1 << (width * 8 - 1)):
        value -= 1 << (width * 8)
    if c_type == 'unsigned long' and value & (1 << 31):
        value -= 1 << 32
    return value


def unit_map():
    artifact = json.loads(UNITS.read_text())
    values = {}
    for row in artifact['rows'][1:]:
        fields = row.split(';')
        values[int(fields[0])] = fields[1]
    return values


def build():
    catalog = json.loads(CATALOG.read_text())
    units = unit_map()
    unit_artifact = json.loads(UNITS.read_text())
    cases, layouts, seen = [], 0, set()
    source_table_hashes = {}

    def emit(ecu, parameter, result, uds_data, *, variant, lookup_value=None):
        pf = parameter['raw'].split(';')
        rf = result['raw'].split(';')
        kind = int(rf[3])
        result_tabs = result.get('tabs', [])
        tab_rows = [tab['raw'] for tab in result_tabs]
        tab_texts = {
            str(tab['text_id']): tab['text']
            for tab in result_tabs if tab.get('text') is not None
        }
        tab_text_states = {
            str(tab['text_id']): ('CAPTURED' if str(tab['text_id']) in tab_texts else 'MISSING')
            for tab in result_tabs
        }
        expected_raw = None
        expected_decoded = True
        expected = None
        reason = None
        expected_text_id = None
        if kind in (2, 3):
            _width, _signed = TYPES[rf[6]]
            raw_value = c_value(raw_bytes(lookup_value if kind == 2 or not rf[9].strip()
                                           else (0 if lookup_value == 0 else decode_int(rf[9])), rf), rf[6])
            expected_raw = raw_value
            target = lookup_value
            if kind == 3 and rf[9].strip():
                mask = decode_int(rf[9])
                target = 1 if (raw_value & mask) > 0 else 0
            matched = next((tab for tab in result_tabs
                            if decode_int(tab['raw'].split(';')[2]) == target), None)
            if matched is None:
                expected = '-'
            elif str(matched['text_id']) not in tab_texts:
                expected_text_id = matched['text_id']
                expected_decoded = False
                reason = 'Localized TAB value text is unavailable'
            else:
                expected_text_id = matched['text_id']
                expected = tab_texts[str(matched['text_id'])]
        elif kind == 4:
            expected = 'ASCII-VALUE'
        else:
            raise AssertionError(f'Unexpected non-NUMBER kind: {kind}')

        # Original common tail uses k21.s only when the PARAMS_TAB list is empty.
        unit_id = int(rf[4])
        assert unit_id in units, (ecu, result['raw'], unit_id)
        if not result_tabs:
            assert result.get('unit', '') == units[unit_id], (ecu, result['raw'], result.get('unit'), units[unit_id])
        expected_unit = (units[unit_id] if not result_tabs and units[unit_id] != '-' else '')
        start = int(pf[3]) + int(rf[7]) - 3
        assert start >= 0, (ecu, parameter['raw'], result['raw'], start)
        layout_key = (ecu, parameter['raw'], result['raw'])
        source_tables = source_table_hashes[ecu]
        cases.append({
            'name': f"{ecu} PARAMS {pf[0]} result {rf[0]} {variant}",
            'ecu_key': ecu,
            'parameter_raw': parameter['raw'],
            'result_raw': result['raw'],
            'format': kind,
            'tabs_raw': tab_rows,
            'tab_texts': tab_texts,
            'tab_text_states': tab_text_states,
            'uds_data': list(uds_data),
            'expected_bytes': list(uds_data[start:start + int(rf[8])]),
            'variant': variant,
            'lookup_value': lookup_value,
            'expected_text_id': expected_text_id,
            'expected_raw': expected_raw,
            'expected_decoded': expected_decoded,
            'expected': expected,
            'reason': reason,
            'expected_unit': expected_unit,
            'unit_id': unit_id,
            'source_unit': units[unit_id],
            'provenance': {
                'kind': 'STATIC_GOLDEN',
                'ecu_key': ecu,
                'layout_key': hashlib.sha256('\n'.join(layout_key).encode()).hexdigest()[:16],
                'params_capture_sha256': source_tables['PARAMS']['sha256'],
                'params_file_sha256': source_tables['PARAMS']['file_sha256'],
                'params_res_capture_sha256': source_tables['PARAMS_RES']['sha256'],
                'params_res_file_sha256': source_tables['PARAMS_RES']['file_sha256'],
                'params_tab_capture_sha256': source_tables['PARAMS_TAB']['sha256'],
                'params_tab_file_sha256': source_tables['PARAMS_TAB']['file_sha256'],
                'dex_sha256': DEX_SHA256,
                'input_kind': 'synthetic response bytes; not physical/original execution',
            },
        })

    for ecu in sorted(catalog):
        target_results = [(parameter, result) for parameter in catalog[ecu]
                          for result in parameter['results']
                          if result['raw'].split(';')[3] in {'2', '3', '4'}]
        if not target_results:
            continue
        table_dir = TABLES / ecu
        source_tables = {}
        for table in ('PARAMS', 'PARAMS_RES', 'PARAMS_TAB'):
            path = table_dir / f'{table}.json'
            artifact = json.loads(path.read_text())
            source_tables[table] = {
                'sha256': artifact['sha256'],
                'file_sha256': sha256(path),
                'rows': set(artifact['rows']),
            }
        source_table_hashes[ecu] = source_tables
        for parameter, result in target_results:
            pf = parameter['raw'].split(';')
            rf = result['raw'].split(';')
            kind = int(rf[3])
            if kind not in (2, 3, 4):
                continue
            layouts += 1
            assert parameter['raw'] in source_tables['PARAMS']['rows']
            assert result['raw'] in source_tables['PARAMS_RES']['rows']
            assert (ecu, parameter['raw'], result['raw']) not in seen
            seen.add((ecu, parameter['raw'], result['raw']))
            tabs = result.get('tabs', [])
            assert all(tab['raw'] in source_tables['PARAMS_TAB']['rows'] for tab in tabs)
            width, _signed = TYPES.get(rf[6], (None, None)) if kind in (2, 3) else (int(rf[8]), False)
            if kind in (2, 3):
                assert width is not None and width == int(rf[8]), (ecu, result['raw'])
            start = int(pf[3]) + int(rf[7]) - 3
            data_len = start + int(rf[8])

            def data_for(value):
                data = [0] * data_len
                b = ([0] * width if kind == 4 else raw_bytes(value, rf))
                data[start:start + width] = b
                return data

            if kind == 4:
                emit(ecu, parameter, result, data_for(0), variant='literal_placeholder')
                continue

            # Preserve each recovered match as an independent exact TAB case.
            for tab in tabs:
                tab_value = decode_int(tab['raw'].split(';')[2])
                if kind == 3 and rf[9].strip():
                    mask = decode_int(rf[9])
                    bits = max(width * 8, 1)
                    value = 0 if tab_value == 0 else (mask & ((1 << bits) - 1))
                    if tab_value not in (0, 1):
                        continue
                else:
                    value = tab_value
                emit(ecu, parameter, result, data_for(value),
                     variant=f'tab_match_{tab_value}', lookup_value=tab_value)

            # A no-match is valid only when a value exists in the actual lookup domain.
            if kind == 3 and rf[9].strip():
                available = {decode_int(t['raw'].split(';')[2]) for t in tabs}
                candidate = next((v for v in (0, 1) if v not in available), None)
                if candidate is not None:
                    mask = decode_int(rf[9])
                    value = 0 if candidate == 0 else (mask & ((1 << (width * 8)) - 1))
                    emit(ecu, parameter, result, data_for(value),
                         variant=f'no_match_{candidate}', lookup_value=candidate)
            else:
                all_values = {decode_int(t['raw'].split(';')[2]) for t in tabs}
                limit = 1 << (width * 8)
                candidate = next((v for v in range(limit) if v not in all_values), None)
                if candidate is not None:
                    emit(ecu, parameter, result, data_for(candidate),
                         variant='no_match_boundary', lookup_value=candidate)

    expected_counts = {2: 30, 3: 187, 4: 1}
    counts = {kind: sum(1 for _ecu, _param, result in seen if int(result.split(';')[3]) == kind)
              for kind in expected_counts}
    assert counts == expected_counts, counts
    return {
        'source': {
            'artifact': 'MotoScan 1.110 classes.dex and recovered native runtime tables',
            'dex_sha256': DEX_SHA256,
            'classification': 'STATIC_GOLDEN; synthetic bytes only, no original execution claimed',
            'layouts': layouts,
            'layout_counts': {'LIST': counts[2], 'DIGITAL': counts[3], 'ASCII': counts[4]},
            'vectors': len(cases),
            'source_catalog_sha256': sha256(CATALOG),
            'units_capture_sha256': unit_artifact['source']['stdout_sha256'],
            'units_file_sha256': sha256(UNITS),
            'expected_rule': 'RE-09 j21.b byte slice, ob2.D C-type read, source TAB lookup and common unit tail; expected values computed in Python only',
            'missing_localized_text_entries': sum(1 for c in cases if c['reason'] == 'Localized TAB value text is unavailable'),
            'placeholder_coverage': {
                'ASCII': 'one recovered source layout; literal ASCII-VALUE case included',
                'BITFIELD': 'DEX literal BITFIELD-VALUE branch documented but no BITFIELD ECU result row exists in the recovered catalog',
            },
        },
        'cases': cases,
    }


def main():
    artifact = build()
    lines = ['{', '  "source": ' + json.dumps(artifact['source'], separators=(',', ':')) + ',', '  "cases": [']
    lines.extend('    ' + json.dumps(case, ensure_ascii=False, separators=(',', ':')) + ','
                 for case in artifact['cases'][:-1])
    lines.append('    ' + json.dumps(artifact['cases'][-1], ensure_ascii=False, separators=(',', ':')))
    lines.extend(['  ]', '}', ''])
    OUTPUT.write_text('\n'.join(lines))
    print(f"Wrote {len(artifact['cases'])} vectors for {artifact['source']['layouts']} layouts")


if __name__ == '__main__':
    main()
