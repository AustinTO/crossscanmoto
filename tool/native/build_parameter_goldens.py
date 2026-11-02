"""Build source-derived static oracle vectors for every retained NUMBER row.

The expected values below implement the MotoScan DEX behavior documented in
docs/parity/RE-09-source-evidence.md. They do not import or execute app code.
"""
import hashlib
import json
import subprocess
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
CATALOG = ROOT / 'assets/data/recovered_uds_parameters.json'
TABLES = ROOT / 'assets/research/recovered-native/runtime-tables'
DEX_SHA256 = '869025551e5339811c300f2ae5ec92563c7e6b228d9498b8e835e2ac79283832'
JAVA_ORACLE = ROOT / 'tool/native/NumberFormatOracle.java'
DEX_OFFSETS = {
    'number_decode': 'j21.b @ 0x26c610-0x26c62a',
    'numeric_dispatch': 'ob2.D @ 0x31d9a4-0x31db8c',
    'big_endian': 'ob2.D @ 0x31d9b4-0x31d9c0',
    'response_bounds': 'j21.b @ 0x26c25c-0x26c282',
    'response_prefix': 'sl0.p @ 0x21f59a-0x21f5c4',
}

# DEX switch behavior. unsigned long's uint32 result is cast to Java int.
TYPES = {
    'unsigned char': (1, False, False),
    'signed char': (1, False, False),
    'char': (1, True, False),
    'unsigned int': (2, False, False),
    'int': (2, True, False),
    'signed int': (2, True, False),
    'unsigned long': (4, False, True),
}


def sha256(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def raw_number(value, width, signed, cast_int):
    """Apply ob2.D's big-endian Java ByteBuffer read and int conversion."""
    bits = width * 8
    if signed and value & (1 << (bits - 1)):
        value -= 1 << bits
    if cast_int and value & (1 << 31):
        value -= 1 << 32
    return value


def boundary_values(width, signed):
    bits = width * 8
    if signed:
        return [
            ('positive_max', (1 << (bits - 1)) - 1),
            ('negative_min', 1 << (bits - 1)),
            ('negative_one', (1 << bits) - 1),
        ]
    return [
        ('zero', 0),
        ('signed_boundary', (1 << (bits - 1)) - 1),
        ('unsigned_max', (1 << bits) - 1),
    ]


def parse_float(fields, index, default):
    return float(fields[index]) if fields[index].strip() else default


def add_java_displays(cases):
    """Use Java Formatter, not a Dart/Python formatter, for expected text."""
    with tempfile.TemporaryDirectory(prefix='params-number-java-') as temp:
        subprocess.run(
            ['javac', '-d', temp, str(JAVA_ORACLE)], check=True,
            stdout=subprocess.PIPE, stderr=subprocess.PIPE,
        )
        input_lines = []
        for case in cases:
            fields = case['result_raw'].split(';')
            input_lines.append('\t'.join((
                str(case['expected_raw']),
                str(parse_float(fields, 11, 1.0)),
                str(parse_float(fields, 12, 1.0)),
                str(parse_float(fields, 13, 0.0)),
            )))
        completed = subprocess.run(
            ['java', '-cp', temp, 'NumberFormatOracle'],
            input='\n'.join(input_lines) + '\n', text=True, check=True,
            stdout=subprocess.PIPE, stderr=subprocess.PIPE,
        )
    output = completed.stdout.splitlines()
    metadata = output.pop(0).split('\t')
    assert metadata[0] == 'META' and metadata[2] == 'en-US', metadata
    assert len(output) == len(cases)
    for case, line in zip(cases, output):
        java_hex, display = line.split('\t')
        java_value = float.fromhex(java_hex)
        assert java_value == case['expected_value'], (
            case['ecu_key'], case['result_raw'], java_hex, case['expected_value']
        )
        case['expected_display'] = display
    return {
        'implementation': 'isolated Java Formatter oracle; no MotoScan code executed',
        'class': 'NumberFormatOracle.java',
        'java_version': metadata[1],
        'locale': metadata[2],
        'format_rule': 'multiplier == 1 && divisor == 1 ? %.0f : %.2f',
        'harness_sha256': sha256(JAVA_ORACLE),
    }


def build():
    catalog = json.loads(CATALOG.read_text())
    cases = []
    seen = set()
    for ecu_key in sorted(catalog):
        for parameter in catalog[ecu_key]:
            parameter_fields = parameter['raw'].split(';')
            for result in parameter['results']:
                fields = result['raw'].split(';')
                if len(fields) <= 13 or fields[3] != '1':
                    continue
                width, signed, cast_int = TYPES[fields[6]]
                offset, length = int(fields[7]), int(fields[8])
                multiplier = parse_float(fields, 11, 1.0)
                divisor = parse_float(fields, 12, 1.0)
                additive = parse_float(fields, 13, 0.0)
                # Original j21.b bounds against base + declared length; ob2.D
                # then reads the width selected by the C-type switch.
                response_data_length = max(offset + length, offset + width)
                table_dir = TABLES / ecu_key
                params_path = table_dir / 'PARAMS.json'
                results_path = table_dir / 'PARAMS_RES.json'
                assert parameter['raw'] in json.loads(params_path.read_text())['rows']
                assert result['raw'] in json.loads(results_path.read_text())['rows']
                provenance = {
                    'kind': 'ACTUAL_NATIVE_ROW',
                    'ecu_key': ecu_key,
                    'params_capture_sha256': json.loads(params_path.read_text())['sha256'],
                    'params_file_sha256': sha256(params_path),
                    'params_res_capture_sha256': json.loads(results_path.read_text())['sha256'],
                    'params_res_file_sha256': sha256(results_path),
                    'dex_sha256': DEX_SHA256,
                    'dex_offsets': DEX_OFFSETS,
                }
                key = (ecu_key, parameter['raw'], result['raw'])
                assert key not in seen
                seen.add(key)
                for label, encoded in boundary_values(width, signed):
                    encoded_bytes = encoded.to_bytes(width, 'big', signed=False)
                    data = [0] * response_data_length
                    data[offset:offset + width] = encoded_bytes
                    response = [0x62, (parameter['did'] >> 8) & 255,
                                parameter['did'] & 255, *data]
                    raw = raw_number(encoded, width, signed, cast_int)
                    # Mirrors the DEX's multiply, then divide, then addition.
                    value = raw * multiplier / divisor + additive
                    cases.append({
                        'ecu_key': ecu_key,
                        'parameter_raw': parameter['raw'],
                        'result_raw': result['raw'],
                        'provenance': provenance,
                        'variant': label,
                        'response_full': response,
                        'base_offset': 3,
                        'absolute_value_offset': 3 + offset,
                        'expected_raw': raw,
                        'expected_value': value,
                    })
    assert len(seen) == 268, f'expected 268 unique NUMBER layouts, got {len(seen)}'
    display_oracle = add_java_displays(cases)
    return {
        'source': {
            'artifact': 'MotoScan 1.110 classes.dex',
            'dex_sha256': DEX_SHA256,
            'classification': 'STATIC_GOLDEN: chosen synthetic response bytes; no original execution is claimed',
            'decoder_rules': 'Big-endian C-type dispatch from ob2.D; full positive SID+DID+data response; result base offset 3; raw * multiplier / divisor + additive offset from j21.b.',
            'layouts': len(seen),
            'vectors_per_layout': 3,
            'display_oracle': display_oracle,
        },
        'cases': cases,
    }


def main():
    output = ROOT / 'test/fixtures/params_number_layout_goldens.json'
    artifact = build()
    # Compact fixture: one JSON object per case keeps review diffs manageable.
    lines = ['{', '  "source": ' + json.dumps(artifact['source'], separators=(',', ':')) + ',', '  "cases": [']
    lines.extend('    ' + json.dumps(case, ensure_ascii=False, separators=(',', ':')) + ','
                 for case in artifact['cases'][:-1])
    lines.append('    ' + json.dumps(artifact['cases'][-1], ensure_ascii=False, separators=(',', ':')))
    lines.extend(['  ]', '}', ''])
    output.write_text('\n'.join(lines))
    print(f"Wrote {len(artifact['cases'])} vectors for {artifact['source']['layouts']} NUMBER layouts")


if __name__ == '__main__':
    main()
