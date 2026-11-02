"""Capture exact native text responses for unresolved PARAMS result ids."""
import hashlib
import json
import subprocess
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
LIBRARY = Path('/tmp/motoscan.so')
PROBE = Path('/tmp/motoscan-text-probe')
OUT = ROOT / 'assets/research/recovered-native/re09-tab-text-reprobes.json'
TABLES = ROOT / 'assets/research/recovered-native/runtime-tables'
TEXTS = ROOT / 'assets/research/recovered-native/localized-texts.ndjson'
EXPECTED_LIBRARY_SHA256 = 'bab0c173bb33c37262d07bbbbdc2c91213275d2a68e941d1b39fc3affd34fc71'


def sha256(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main():
    if sha256(LIBRARY) != EXPECTED_LIBRARY_SHA256:
        raise SystemExit('Unexpected native library SHA-256')
    known_text_ids = set()
    for line in TEXTS.read_text(encoding='utf-8').splitlines():
        record = json.loads(line)
        if record.get('method') == 't':
            known_text_ids.add(record['id'])
    tab_ids, result_label_ids = set(), set()
    source_hashes = {}
    for result_path in sorted(TABLES.glob('*/PARAMS_RES.json')):
        folder = result_path.parent
        result_table = json.loads(result_path.read_text(encoding='utf-8'))
        params_path, tabs_path = folder / 'PARAMS.json', folder / 'PARAMS_TAB.json'
        if not params_path.exists():
            continue
        params = json.loads(params_path.read_text(encoding='utf-8'))
        parent_ids = {int(raw.split(';')[0]) for raw in params['rows'] if raw.split(';')[0].isdigit()}
        result_ids = set()
        for raw in result_table['rows']:
            fields = raw.split(';')
            if len(fields) <= 14 or not fields[0].isdigit() or not fields[1].isdigit():
                continue
            if int(fields[1]) not in parent_ids:
                continue
            result_ids.add(int(fields[0]))
            try:
                label_id = int(fields[14])
            except ValueError:
                continue
            if label_id not in known_text_ids:
                result_label_ids.add(label_id)
        source_hashes[folder.name] = {
            'params': params.get('sha256'),
            'params_res': result_table.get('sha256'),
            'params_tab': json.loads(tabs_path.read_text(encoding='utf-8')).get('sha256') if tabs_path.exists() else None,
        }
        if tabs_path.exists():
            for raw in json.loads(tabs_path.read_text(encoding='utf-8'))['rows']:
                fields = raw.split(';')
                if len(fields) <= 3 or not fields[1].isdigit() or int(fields[1]) not in result_ids:
                    continue
                try:
                    text_id = int(fields[3])
                except ValueError:
                    continue
                if text_id not in known_text_ids:
                    tab_ids.add(text_id)
    ids = sorted(tab_ids | result_label_ids)
    results = []
    with tempfile.TemporaryDirectory(prefix='re09-text-') as temp_dir:
        id_file = Path(temp_dir) / 'id.txt'
        for text_id in ids:
            id_file.write_text(f'{text_id}\n')
            command = [
                'prlimit', '--cpu=5', '--as=1073741824', 'qemu-aarch64',
                '-L', '/usr/aarch64-linux-gnu', str(PROBE), str(LIBRARY),
                '--id', str(id_file.read_text().strip()),
            ]
            run = subprocess.run(command, capture_output=True, timeout=10)
            stdout = run.stdout.decode('utf-8', errors='replace')
            results.append({
                'id': text_id,
                'exit_code': run.returncode,
                'stdout_sha256': hashlib.sha256(run.stdout).hexdigest(),
                'stdout': stdout,
                'stderr': run.stderr.decode('utf-8', errors='replace')[:300],
            })
    payload = {
        'evidence_type': 'offline native localized-text function lookup under QEMU',
        'source': {
            'apk_sha256': 'bfc07ce264a0c35df9d63558f4fa64c4bd3dd845903d3e0417532250ea0e7e58',
            'library_sha256': EXPECTED_LIBRARY_SHA256,
            'probe_source': 'tool/native/text_probe.c',
            'probe_source_sha256': sha256(ROOT / 'tool/native/text_probe.c'),
            'probe_binary_sha256': sha256(PROBE),
            'method_mapping': 'DEX Les0.s -> NativeLibMotoScan.I -> private NativeLibMotoScan.t; this artifact records all method outputs from text_probe.c.',
            'runtime_table_sha256_by_ecu': source_hashes,
            'query_stdout_sha256': hashlib.sha256(
                ''.join(r['stdout'] for r in results).encode('utf-8')
            ).hexdigest(),
        },
        'queried_id_count': len(ids),
        'queried_ids': ids,
        'tab_value_ids': sorted(tab_ids),
        'result_label_ids': sorted(result_label_ids),
        'results': results,
        'limits': 'No Android app process, network, or vehicle connection. Raw method outputs are preserved, including literal "unknown text" responses and nonzero exit statuses.',
    }
    OUT.write_text(json.dumps(payload, ensure_ascii=False, indent=2) + '\n')
    unknown = sum('t\tunknown text' in row['stdout'] for row in results)
    print(f'Queried {len(ids)} ids; native t returned "unknown text" for {unknown}')


if __name__ == '__main__':
    main()
