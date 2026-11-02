"""Capture bounded ECU PARAMS/PARAMS_TAB_GLOBAL query outcomes offline.

This uses the existing table_probe binary and controlled QEMU loader. It does
not launch the Android app or communicate with a vehicle or network.
"""
import hashlib
import json
import re
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
LIBRARY = Path('/tmp/motoscan.so')
PROBE = Path('/tmp/motoscan-table-probe')
OUT = ROOT / 'assets/research/recovered-native/re09-tab-global-probes.json'
EXPECTED_LIBRARY_SHA256 = 'bab0c173bb33c37262d07bbbbdc2c91213275d2a68e941d1b39fc3affd34fc71'


def sha256(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def run_query(key, table):
    command = [
        'prlimit', '--cpu=5', '--as=1073741824', 'qemu-aarch64',
        '-L', '/usr/aarch64-linux-gnu', str(PROBE), str(LIBRARY), key, table,
    ]
    run = subprocess.run(command, capture_output=True, timeout=10)
    stdout = run.stdout.decode('utf-8', errors='replace')
    stderr = run.stderr.decode('utf-8', errors='replace')[:500]
    count = re.search(r'rows=(\d+)', stderr)
    status = 'error'
    if run.returncode == 0 and count:
        status = 'empty' if int(count.group(1)) == 0 else 'nonempty'
    return {
        'status': status,
        'exit_code': run.returncode,
        'reported_rows': int(count.group(1)) if count else None,
        'stdout_sha256': hashlib.sha256(run.stdout).hexdigest(),
        'rows': stdout.splitlines() if table == 'PARAMS_TAB_GLOBAL' and status == 'nonempty' else [],
        'error': stderr if status == 'error' else None,
    }


def main():
    if sha256(LIBRARY) != EXPECTED_LIBRARY_SHA256:
        raise SystemExit('Unexpected native library SHA-256')
    keys = json.loads((ROOT / 'assets/research/recovered-native/observed-ecu-keys.json').read_text())
    supported_params = {
        path.parent.name for path in
        (ROOT / 'assets/research/recovered-native/runtime-tables').glob('*/PARAMS.json')
    }
    results = []
    for key in keys:
        params = run_query(key, 'PARAMS')
        tab_global = run_query(key, 'PARAMS_TAB_GLOBAL')
        results.append({
            'ecu_key': key,
            'params_capture_present': key in supported_params,
            'params_probe': {k: v for k, v in params.items() if k != 'rows'},
            'params_tab_global_probe': tab_global,
        })
    payload = {
        'evidence_type': 'legacy offline native object/vtable query via custom ELF loader under QEMU',
        'interpretation': 'Superseded by re09-jni-table-probes.json, which follows the actual public n(String,String) -> private j(String,String) path. Invalid row-count outputs here are not proof of table absence.',
        'source': {
            'apk_sha256': 'bfc07ce264a0c35df9d63558f4fa64c4bd3dd845903d3e0417532250ea0e7e58',
            'library_sha256': EXPECTED_LIBRARY_SHA256,
            'probe_source': 'tool/native/table_probe.c',
            'probe_source_sha256': sha256(ROOT / 'tool/native/table_probe.c'),
            'probe_binary_sha256': sha256(PROBE),
            'ecu_keys_source': 'assets/research/recovered-native/observed-ecu-keys.json',
        },
        'limits': 'No app process, network access, or ECU/vehicle connection; CPU and address space bounded per query.',
        'results': results,
    }
    OUT.write_text(json.dumps(payload, ensure_ascii=False, indent=2) + '\n')
    print(f'Wrote {len(results)} ECU query outcomes to {OUT}')


if __name__ == '__main__':
    main()
