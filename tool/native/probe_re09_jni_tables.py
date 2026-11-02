"""Replay native n(String,String) table access through its JNI implementation.

This calls private JNI j, the implementation behind Java's public n wrapper,
using a minimal fake JNIEnv. It is offline, bounded, and never changes license
or keyvault state.
"""
import hashlib
import json
import re
import subprocess
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
NATIVE = ROOT / 'assets/research/recovered-native'
TABLES = NATIVE / 'runtime-tables'
LIBRARY = Path('/tmp/motoscan.so')
PROBE = Path('/tmp/motoscan-jni-table-probe')
SOURCE = ROOT / 'tool/native/jni_table_probe.c'
OUT = NATIVE / 're09-jni-table-probes.json'
EXPECTED_LIBRARY_SHA256 = 'bab0c173bb33c37262d07bbbbdc2c91213275d2a68e941d1b39fc3affd34fc71'


def sha256(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def build_probe():
    run = subprocess.run(
        ['aarch64-linux-gnu-gcc', '-O2', str(SOURCE), '-ldl', '-o', str(PROBE)],
        capture_output=True, text=True, timeout=30,
    )
    if run.returncode:
        raise SystemExit(run.stderr)


def probe(ecu_key, table):
    command = [
        'prlimit', '--cpu=5', '--as=1073741824', 'qemu-aarch64',
        '-L', '/usr/aarch64-linux-gnu', str(PROBE), str(LIBRARY), ecu_key, table,
    ]
    run = subprocess.run(command, capture_output=True, timeout=10)
    stdout = run.stdout
    stderr = run.stderr.decode('utf-8', errors='replace')[:500]
    count = re.search(r'rows=(\d+)', stderr)
    if run.returncode == 0 and count:
        status = 'empty' if int(count.group(1)) == 0 else 'nonempty'
    elif run.returncode == 3 and 'native j returned null' in stderr:
        status = 'null'
    else:
        status = 'error'
    return {
        'status': status,
        'exit_code': run.returncode,
        'reported_rows': int(count.group(1)) if count else None,
        'stdout_sha256': hashlib.sha256(stdout).hexdigest(),
        'rows': stdout.decode('utf-8', errors='replace').splitlines(),
        'error': stderr if status == 'error' else None,
    }


def main():
    if sha256(LIBRARY) != EXPECTED_LIBRARY_SHA256:
        raise SystemExit('Unexpected native library SHA-256')
    build_probe()
    keys = json.loads((NATIVE / 'observed-ecu-keys.json').read_text(encoding='utf-8'))
    rows = []
    for key in keys:
        params = probe(key, 'PARAMS')
        tab_global = probe(key, 'PARAMS_TAB_GLOBAL')
        capture_path = TABLES / key / 'PARAMS.json'
        params_capture = json.loads(capture_path.read_text(encoding='utf-8')) if capture_path.exists() else None
        matches_capture = bool(params_capture and
                               params['reported_rows'] == len(params_capture['rows']) and
                               params['stdout_sha256'] == params_capture['sha256'])
        if params['status'] == 'nonempty' and not matches_capture:
            params['rows'] = params['rows']
        else:
            params['rows'] = []
        rows.append({
            'ecu_key': key,
            'params_capture_present': params_capture is not None,
            'params_control_matches_capture': matches_capture if params_capture else None,
            'params_probe': params,
            'params_tab_global_probe': tab_global,
        })

    payload = {
        'evidence_type': 'private JNI table method used by public n(String,String), offline via bounded custom ELF loader/QEMU',
        'captured_at_utc': datetime.now(timezone.utc).isoformat(),
        'source': {
            'apk_sha256': 'bfc07ce264a0c35df9d63558f4fa64c4bd3dd845903d3e0417532250ea0e7e58',
            'library_sha256': EXPECTED_LIBRARY_SHA256,
            'public_dex_wrapper': 'NativeLibMotoScan.n(String,String), DEX 0x4e4118 calls private j(String,String) and maps null to an empty String[].',
            'private_j_dex_signature': 'NativeLibMotoScan.j(String,String), private native.',
            'private_j_elf_rva': '0x6f6d84',
            'probe_source': str(SOURCE.relative_to(ROOT)),
            'probe_source_sha256': sha256(SOURCE),
            'probe_binary_sha256': sha256(PROBE),
            'ecu_keys_source': 'assets/research/recovered-native/observed-ecu-keys.json',
        },
        'limits': 'No app process, network, or vehicle. Fake JNIEnv only supports the string and object-array calls used by private j; CPU/address space bounded per invocation. JNI null is preserved distinctly even though the public wrapper converts it to an empty array.',
        'results': rows,
    }
    OUT.write_text(json.dumps(payload, ensure_ascii=False, indent=2) + '\n')
    print(f'Wrote {len(rows)} two-table JNI query outcomes to {OUT}')


if __name__ == '__main__':
    main()
