#!/usr/bin/env python3
"""Offline extraction and structured compilation of MotoScan native ECU coding tables.

Extracts all embedded coding schemas from motoscan.so via the verified JNI query interface
(Java_de_wgsoft_libwgsoftnativemotoscan_NativeLibMotoScan_l, symbol 0x6f7474).
No network calls, no keyvault state alteration, fully reproducible.
"""

import hashlib
import json
import os
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
LIBRARY = Path('/tmp/motoscan.so')
PROBE_BIN = Path('/tmp/coding_probe')
DATA_OUT = ROOT / 'assets/data/recovered_coding_definitions.json'
RAW_OUT_DIR = ROOT / 'assets/research/recovered-native/coding-tables'

EXPECTED_LIBRARY_SHA256 = 'bab0c173bb33c37262d07bbbbdc2c91213275d2a68e941d1b39fc3affd34fc71'

CODING_TABLE_KEYS = [
    'AUDIO_C02', 'AUDIO_C03',
    'BMSE_C00',
    'BMSK_C00', 'BMSK_C01', 'BMSK_C02', 'BMSK_C03',
    'BMSM_C01',
    'DWA_K25_C01', 'DWA_K25_C02', 'DWA_K25_C04',
    'IABS_C04', 'IABS_C05', 'IABS_C06', 'IABS_C07', 'IABS_C08', 'IABS_C09', 'IABS_C0A', 'IABS_C0B',
    'KMBI_2D_C01', 'KMBI_2D_C02',
    'KMBI_K18_C03',
    'KMBI_K25_C03', 'KMBI_K25_C04', 'KMBI_K25_C05', 'KMBI_K25_C06', 'KMBI_K25_C07',
    'KMBI_K46_C02',
    'KMBI_K71_C01', 'KMBI_K71_C02',
    'RBT_K26_C01', 'RBT_K26_C02',
    'RDC_K44_C01', 'RDC_K44_C02', 'RDC_K44_C03', 'RDC_K44_C04',
    'SAF_C03',
    'ZFEB_C07', 'ZFEB_C09', 'ZFEB_C10',
    'ZFEH_C07', 'ZFEH_C09', 'ZFEH_C30',
    'ZFE_C02', 'ZFE_C06', 'ZFE_C07', 'ZFE_C08', 'ZFE_C09'
]


def ensure_probe_compiled():
    if PROBE_BIN.exists() and os.access(PROBE_BIN, os.X_OK):
        return
    c_src = ROOT / 'tool/native/jni_table_probe.c'
    # Use jni_table_probe or compile dedicated probe
    print('Building probe...')
    subprocess.run(
        ['aarch64-linux-gnu-gcc', '-O2', '/tmp/coding_probe.c', '-ldl', '-o', str(PROBE_BIN)],
        check=True
    )


def extract_table(key: str) -> list[str]:
    cmd = [
        'prlimit', '--cpu=5', '--as=1073741824',
        'qemu-aarch64', '-L', '/usr/aarch64-linux-gnu',
        str(PROBE_BIN), str(LIBRARY), key
    ]
    res = subprocess.run(cmd, capture_output=True, text=True, timeout=10)
    if res.returncode != 0:
        return []
    return [line.strip() for line in res.stdout.splitlines() if line.strip()]


def parse_table_lines(key: str, lines: list[str]) -> dict:
    header = ''
    ecu_family = ''
    coding_index = ''
    blocks = []
    curr_block = None
    curr_param = None

    if '_' in key:
        parts = key.rsplit('_C', 1)
        if len(parts) == 2:
            ecu_family = parts[0]
            coding_index = parts[1]

    for line in lines:
        parts = line.split(';')
        tag = parts[0]

        if tag == '00':
            header = parts[1] if len(parts) > 1 else ''
        elif tag == '06':
            # 06;SectionName;DID;Offset;Length
            name = parts[1] if len(parts) > 1 else ''
            did_hex = parts[2] if len(parts) > 2 else '0'
            did_int = int(did_hex, 16) & 0xFFFF
            offset = int(parts[3], 16) if len(parts) > 3 and parts[3] else 0
            length = int(parts[4], 16) if len(parts) > 4 and parts[4] else 0
            curr_block = {
                'name': name,
                'did_hex': f'0x{did_int:04X}',
                'did': did_int,
                'offset': offset,
                'length': length,
                'parameters': []
            }
            blocks.append(curr_block)
            curr_param = None
        elif tag == '12':
            # 12;NAME;DID;OFFSET;LENGTH;TEXT_ID;OPTIONS_MASK;BITMASK;DEFAULT;
            p_name = parts[1] if len(parts) > 1 else ''
            p_did = int(parts[2], 16) & 0xFFFF if len(parts) > 2 and parts[2] else 0
            p_offset = int(parts[3], 16) if len(parts) > 3 and parts[3] else 0
            p_length = int(parts[4], 16) if len(parts) > 4 and parts[4] else 1
            p_text_id = parts[5] if len(parts) > 5 else ''
            p_options_mask = parts[6] if len(parts) > 6 else ''
            p_bitmask = parts[7] if len(parts) > 7 and parts[7] else 'FF'
            p_default = parts[8] if len(parts) > 8 else ''
            p_init = parts[9] if len(parts) > 9 else ''

            curr_param = {
                'name': p_name,
                'did': p_did,
                'offset': p_offset,
                'length': p_length,
                'text_id': p_text_id,
                'options_mask': p_options_mask,
                'bitmask_hex': p_bitmask,
                'bitmask': int(p_bitmask, 16) if p_bitmask else 0xFF,
                'default_flag': p_default,
                'init_value': p_init,
                'options': []
            }
            if curr_block is not None:
                curr_block['parameters'].append(curr_param)
        elif tag == '10':
            # 10;OptionName;RawHex
            opt_name = parts[1] if len(parts) > 1 else ''
            opt_hex = parts[2] if len(parts) > 2 else ''
            if curr_param is not None:
                curr_param['options'].append({
                    'name': opt_name,
                    'raw_hex': opt_hex
                })

    return {
        'key': key,
        'ecu_family': ecu_family,
        'coding_index': coding_index,
        'header': header,
        'line_count': len(lines),
        'block_count': len(blocks),
        'parameter_count': sum(len(b['parameters']) for b in blocks),
        'blocks': blocks
    }


def main():
    if not LIBRARY.exists():
        print(f'Error: {LIBRARY} not found', file=sys.stderr)
        sys.exit(1)

    lib_hash = hashlib.sha256(LIBRARY.read_bytes()).hexdigest()
    if lib_hash != EXPECTED_LIBRARY_SHA256:
        print(f'Warning: Library hash mismatch: {lib_hash}', file=sys.stderr)

    ensure_probe_compiled()
    RAW_OUT_DIR.mkdir(parents=True, exist_ok=True)

    catalog = {
        'generator': 'CrossScanMoto native coding extractor (tool/native/extract_native_coding_tables.py)',
        'source_library': 'libmotoscan-helper.so (MotoScan 1.110)',
        'source_library_sha256': lib_hash,
        'extraction_method': 'offline QEMU execution of NativeLibMotoScan_l (0x6f7474) dispatching 0x6fc750',
        'variants': {}
    }

    total_params = 0
    total_options = 0

    print(f'Extracting {len(CODING_TABLE_KEYS)} coding tables...')
    for key in sorted(CODING_TABLE_KEYS):
        lines = extract_table(key)
        if not lines:
            print(f'  {key}: EMPTY/FAILED')
            continue

        # Save raw lines
        raw_path = RAW_OUT_DIR / f'{key}.txt'
        raw_path.write_text('\n'.join(lines), encoding='utf-8')

        parsed = parse_table_lines(key, lines)
        catalog['variants'][key] = parsed
        total_params += parsed['parameter_count']
        total_options += sum(
            len(p['options'])
            for b in parsed['blocks']
            for p in b['parameters']
        )
        print(f'  {key}: {parsed["block_count"]} blocks, {parsed["parameter_count"]} params, {len(lines)} lines')

    catalog['total_variants'] = len(catalog['variants'])
    catalog['total_parameters'] = total_params
    catalog['total_options'] = total_options

    DATA_OUT.parent.mkdir(parents=True, exist_ok=True)
    with open(DATA_OUT, 'w', encoding='utf-8') as f:
        json.dump(catalog, f, indent=2, ensure_ascii=False)

    print(f'\nSuccess! Compiled {len(catalog["variants"])} variants, {total_params} parameters, {total_options} options into {DATA_OUT}')


if __name__ == '__main__':
    main()
