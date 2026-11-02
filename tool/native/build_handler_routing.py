"""Build source-backed RE-02 routing edges without fuzzy vehicle/ECU joins."""
import hashlib
import json
import re
from collections import Counter, defaultdict
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
NATIVE = ROOT / 'assets/research/recovered-native'
TABLES = NATIVE / 'runtime-tables'
OUT = NATIVE / 'handler-routing.json'

FUNCTION_ENUM = {
    0: 'CF_UNKNOWN',
    1: 'CF_IDENTIFICATION',
    2: 'CF_DTCREAD',
    3: 'CF_DTCCLEAR',
    4: 'CF_CONFIG',
    5: 'CF_LIVEDATA',
    6: 'CF_ACTORS',
    7: 'CF_CODING',
    8: 'CF_ADAPTIONS',
    9: 'CF_UNKNOWN',
    10: 'CF_UNKNOWN',
    11: 'CF_SERVICE_FUNCTIONS',
    12: 'CF_SERVICE',
    13: 'CF_PROGRAMMINGINFO',
    14: 'CF_INFODTCREAD',
    15: 'CF_INFODTCCLEAR',
}


def read_json(path):
    return json.loads(path.read_text(encoding='utf-8'))


def file_hash(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def source(path, digest, *, row_index=None, row_id=None, offset=None):
    result = {'path': path, 'sha256': digest}
    if row_index is not None:
        result['row_index'] = row_index
    if row_id is not None:
        result['row_id'] = row_id
    if offset is not None:
        result['offset'] = offset
    return result


def main():
    paths = {
        'vehicles': NATIVE / 'vehicle-records.json',
        'series': NATIVE / 'series.json',
        'platform_edges': NATIVE / 'platform-ecu-groups.json',
        'groups': NATIVE / 'ecu-groups.json',
        'keys': NATIVE / 'observed-ecu-keys.json',
        'index': NATIVE / 'runtime-tables-index.json',
        'validation': NATIVE / 'runtime-extraction-validation.json',
        'jni': NATIVE / 're09-jni-table-probes.json',
        'factory_excerpt': ROOT / 'docs/parity/fixtures/RE-02-native-factory-key-checks.txt',
        'function_excerpt': ROOT / 'docs/parity/fixtures/RE-02-functions-routing-excerpts.txt',
        'dex_schema_excerpt': ROOT / 'assets/research/native-schema-disassembly.txt',
        'native_factory_excerpt': ROOT / 'assets/research/native-ecu-factory.asm',
        'table_j_asm': ROOT / 'assets/research/native-table-j.asm',
    }
    hashes = {name: file_hash(path) for name, path in paths.items()}
    vehicles = read_json(paths['vehicles'])
    series = read_json(paths['series'])
    platform_edges = read_json(paths['platform_edges'])
    groups = read_json(paths['groups'])
    keys = read_json(paths['keys'])
    index = read_json(paths['index'])
    validation = read_json(paths['validation'])
    jni_results = {item['ecu_key']: item for item in read_json(paths['jni'])['results']}

    direct_edges = []
    unresolved_edges = []
    vehicle_hash, series_hash = hashes['vehicles'], hashes['series']
    platform_hash, group_hash = hashes['platform_edges'], hashes['groups']
    series_ids = {record['id'] for record in series['records']}
    group_ids = {record['id'] for record in groups['records']}
    platform_ids = {record['car_platformid'] for record in platform_edges['records']}
    missing_series, missing_platform_group = [], []

    for row_index, row in enumerate(vehicles):
        series_id = row['car_seriesid']
        platform_id = row['car_platformid']
        if series_id not in series_ids:
            missing_series.append({'vehicle_id': row['id'], 'series_id': series_id})
        if platform_id not in platform_ids:
            missing_platform_group.append({'vehicle_id': row['id'], 'platform_id': platform_id})
        direct_edges.append({
            'kind': 'vehicle_to_series',
            'from': {'type': 'vehicle', 'id': row['id']},
            'to': {'type': 'series', 'id': series_id},
            'raw_row': row,
            'join_fields': ['vehicle.car_seriesid', 'series.id'],
            'source': source('assets/research/recovered-native/vehicle-records.json', vehicle_hash,
                             row_index=row_index, row_id=row['id']),
        })
        direct_edges.append({
            'kind': 'vehicle_to_platform',
            'from': {'type': 'vehicle', 'id': row['id']},
            'to': {'type': 'platform', 'id': platform_id},
            'raw_row': row,
            'join_fields': ['vehicle.car_platformid', 'platform-ecu-groups.car_platformid'],
            'source': source('assets/research/recovered-native/vehicle-records.json', vehicle_hash,
                             row_index=row_index, row_id=row['id']),
        })
        direct_edges.append({
            'kind': 'vehicle_diagid_raw_field',
            'from': {'type': 'vehicle', 'id': row['id']},
            'field': 'diagid',
            'value': row.get('diagid', ''),
            'raw_row': row,
            'source': source('assets/research/recovered-native/vehicle-records.json', vehicle_hash,
                             row_index=row_index, row_id=row['id']),
            'interpretation': 'Literal vehicle-table field; no protocol or ECU-key join is assumed.',
        })

    for row_index, row in enumerate(platform_edges['records']):
        group_id = row['ecu_groupsid']
        if group_id not in group_ids:
            missing_platform_group.append({'platform_id': row['car_platformid'], 'group_id': group_id})
        direct_edges.append({
            'kind': 'platform_to_ecu_group',
            'from': {'type': 'platform', 'id': row['car_platformid']},
            'to': {'type': 'ecu_group', 'id': group_id},
            'raw_row': row,
            'join_fields': ['platform-ecu-groups.car_platformid', 'vehicle.car_platformid',
                            'platform-ecu-groups.ecu_groupsid', 'ecu-groups.id'],
            'source': source('assets/research/recovered-native/platform-ecu-groups.json', platform_hash,
                             row_index=row_index),
        })

    protocol_counts = Counter()
    for row_index, row in enumerate(groups['records']):
        row_source = source('assets/research/recovered-native/ecu-groups.json', group_hash,
                            row_index=row_index, row_id=row['id'])
        protocol_counts[row['defaultprotocolid']] += 1
        for field, kind, target_type in [
            ('modulegroup', 'ecu_group_to_modulegroup_field', 'modulegroup'),
            ('defaultprotocolid', 'ecu_group_to_protocol_id_field', 'protocol_id'),
            ('defaultaddress', 'ecu_group_to_default_address_field', 'address'),
        ]:
            direct_edges.append({
                'kind': kind,
                'from': {'type': 'ecu_group', 'id': row['id']},
                'to': {'type': target_type, 'value': row[field]},
                'field': field,
                'raw_row': row,
                'source': row_source,
                'interpretation': 'Raw source field; no mapping to ECU key suffixes, Dart protocol enums, or transport handler is inferred.',
            })

    success_by_key = defaultdict(list)
    errors_by_key = defaultdict(list)
    for item in index:
        if 'row_count' in item:
            success_by_key[item['key']].append(item)
        elif 'exit_code' in item:
            errors_by_key[item['key']].append(item)

    function_rows, function_counts, included_counts = [], {}, {}
    function_flag_patterns = Counter()
    for key, table_records in success_by_key.items():
        function_index = next((row for row in table_records if row['table'] == 'FUNCTIONS'), None)
        if function_index is None:
            continue
        path = TABLES / key / 'FUNCTIONS.json'
        payload = read_json(path)
        function_counts[key] = len(payload['rows'])
        included_counts[key] = 0
        for row_index, raw in enumerate(payload['rows']):
            fields = raw.split(';')
            try:
                type_id = int(fields[0])
            except (IndexError, ValueError):
                type_id = None
            try:
                include_flag = int(fields[1]) == 1
            except (IndexError, ValueError):
                include_flag = None
            try:
                label_id = int(fields[6])
            except (IndexError, ValueError):
                label_id = None
            if include_flag:
                included_counts[key] += 1
            if len(fields) >= 6:
                function_flag_patterns[';'.join(fields[1:6])] += 1
            function_rows.append({
                'kind': 'ecu_key_to_FUNCTIONS_row',
                'from': {'type': 'ecu_key', 'value': key},
                'function_type_id': type_id,
                'function_category': FUNCTION_ENUM.get(type_id, 'CF_UNKNOWN'),
                'loader_include_flag': include_flag,
                'loader_retains_row': include_flag,
                'token2_to_token5_raw': fields[2:6] if len(fields) > 2 else [],
                'token6_localization_id': label_id,
                'raw_row': raw,
                'source': source(f'assets/research/recovered-native/runtime-tables/{key}/FUNCTIONS.json',
                                 payload.get('sha256', function_index['sha256']),
                                 row_index=row_index),
                'dex_evidence': {
                    'parser': 'jl0.<init> at 0x2198b4',
                    'loader_gate': 'fl0.g at 0x217e12-0x217e38 includes only jl0.b == true',
                    'function_type_switch': 'jl0.<init> token0 packed switch at 0x219902; packed targets at 0x2199bc',
                },
            })

    function_edges = []
    for key, count in function_counts.items():
        for function_id, category in FUNCTION_ENUM.items():
            matched = [row for row in function_rows if row['from']['value'] == key and row['function_type_id'] == function_id]
            if matched:
                function_edges.append({
                    'kind': 'ecu_key_FUNCTIONS_category_visibility',
                    'from': {'type': 'ecu_key', 'value': key},
                    'to': {'type': 'function_category', 'value': category, 'source_type_id': function_id},
                    'rows_present': len(matched),
                    'rows_retained_by_loader': sum(1 for row in matched if row['loader_retains_row']),
                    'raw_rows': [row['raw_row'] for row in matched],
                    'source': {'table': 'FUNCTIONS', 'dex': 'jl0/fl0 offsets in function row sources'},
                    'limit': 'This proves catalog category and loader inclusion only; not an executable transport handler or physical compatibility.',
                })

    re09_jni = {row['ecu_key']: row for row in read_json(NATIVE / 're09-jni-table-probes.json')['results']}
    candidates = []
    for key in keys:
        success = success_by_key.get(key, [])
        errors = errors_by_key.get(key, [])
        candidates.append({
            'ecu_key': key,
            'classification': 'returned_nonempty_table_rows' if success else ('legacy_failed_only_candidate' if errors else 'no_nonempty_table_row_in_index'),
            'successful_tables': [{'table': row['table'], 'row_count': row['row_count'], 'rows_sha256': row['sha256']} for row in success],
            'legacy_error_tables': [{'table': row['table'], 'exit_code': row['exit_code'], 'error': row.get('error')} for row in errors],
            'legacy_failure_count': len(errors),
            're09_private_j_status': {
                'PARAMS': re09_jni.get(key, {}).get('params_probe'),
                'PARAMS_TAB_GLOBAL': re09_jni.get(key, {}).get('params_tab_global_probe'),
            } if key in re09_jni else None,
            'interpretation': 'A table response or failed probe is ECU-key evidence only; no vehicle compatibility is asserted.',
        })

    unindexed_functions = []
    for path in sorted(TABLES.glob('*/FUNCTIONS.json')):
        key = path.parent.name
        if any(row['key'] == key and row['table'] == 'FUNCTIONS' and 'row_count' in row for row in index):
            continue
        payload = read_json(path)
        unindexed_functions.append({
            'ecu_key': key,
            'table': 'FUNCTIONS',
            'row_count': len(payload['rows']),
            'rows_sha256': payload.get('sha256'),
            'payload_path': str(path.relative_to(ROOT)),
            'evidence_type': payload.get('evidence_type'),
            'status': 'local payload without matching successful runtime index entry; not counted among the 234 successful actions',
        })

    factory_excerpt_path = ROOT / 'docs/parity/fixtures/RE-02-native-factory-key-checks.txt'
    factory_literals = []
    current = None
    for line in factory_excerpt_path.read_text(encoding='utf-8').splitlines():
        match = re.match(r'ELF literal (0x[0-9a-f]+): (.+)$', line)
        if match:
            current = {'literal_elf_rva': match.group(1), 'ecu_key_literal': match.group(2)}
            factory_literals.append(current)
        elif current is not None and 'bl' in line and '6fd924' in line:
            match = re.match(r'\s*([0-9a-f]+):', line)
            if match:
                current['comparison_call_elf_rva'] = hex(int(match.group(1), 16))
    candidate_key_set = set(keys)
    for item in factory_literals:
        item['exactly_in_observed_68_candidate_strings'] = item['ecu_key_literal'] in candidate_key_set
        item['class_or_diagnostic_handler'] = None
        item['limit'] = 'Literal is passed to the native factory comparison helper; resulting provider subtype and protocol semantics are not named in retained source.'

    unindexed_unresolved = []
    if missing_series:
        unindexed_unresolved.extend({'kind': 'vehicle_series_missing', **row} for row in missing_series)
    if missing_platform_group:
        unindexed_unresolved.extend({'kind': 'platform_group_missing', **row} for row in missing_platform_group)

    artifact = {
        'schema_version': 1,
        'source': {
            'artifact': 'MotoScan 1.110 APK and arm64 libmotoscan-helper.so',
            'apk_sha256': 'bfc07ce264a0c35df9d63558f4fa64c4bd3dd845903d3e0417532250ea0e7e58',
            'classes_dex_sha256': '869025551e5339811c300f2ae5ec92563c7e6b228d9498b8e835e2ac79283832',
            'library_sha256': 'bab0c173bb33c37262d07bbbbdc2c91213275d2a68e941d1b39fc3affd34fc71',
            'input_sha256_by_path': hashes,
            'counts': {
                'vehicles': len(vehicles), 'series': len(series['records']), 'ecu_groups': len(groups['records']),
                'platform_ecu_group_edges': len(platform_edges['records']), 'candidate_ecu_key_strings': len(keys),
                'keys_with_successful_nonempty_table_outputs': len(set(success_by_key) & candidate_key_set),
                'legacy_failure_only_candidates': sum(bool(errors_by_key.get(key)) and not success_by_key.get(key) for key in keys),
                'legacy_indexed_failed_actions': validation['failed_probes'], 'indexed_successful_rows': validation['validated_rows'],
                'indexed_FUNCTIONS_rows': len(function_rows), 'FUNCTIONS_ECU_keys': len(function_counts),
                'FUNCTIONS_rows_retained_by_loader': sum(included_counts.values()),
                'FUNCTIONS_rows_filtered_by_loader': len(function_rows)-sum(included_counts.values()),
                'unindexed_local_FUNCTIONS_files': len(unindexed_functions),
            },
            'dex_offsets': {
                'fl0.g ECU-scoped loader': '0x217984',
                'FUNCTIONS query and include flag': '0x217dfa-0x217e38',
                'jl0 FUNCTIONS row parser': '0x2198b4',
                'jl0 numeric function-type switch': '0x219902, packed switch data 0x2199bc',
                'kl0 category enum': '0x219704',
                'public n(String,String) wrapper': '0x4e4118',
                'private native j(String,String)': 'ELF RVA 0x6f6d84',
                'native table-provider factory': 'ELF RVA 0x88e3d0',
            },
        },
        'direct_edges': direct_edges + function_rows,
        'handler_edges': [
            {
                'kind': 'ECU_key_to_native_metadata_query',
                'from': {'type': 'ecu_key', 'value': 'fl0.g(String) current ECU argument'},
                'to': {'type': 'native_table_query', 'handler': 'public NativeLibMotoScan.n(String,String) -> private j(String,String) -> native provider factory'},
                'source': [
                    {'path': 'assets/research/native-schema-disassembly.txt', 'sha256': hashes['dex_schema_excerpt'], 'offset': '0x217984'},
                    {'path': 'assets/research/native-table-j.asm', 'sha256': hashes['table_j_asm'], 'offset': '0x6f6d84'},
                    {'path': 'assets/research/native-ecu-factory.asm', 'sha256': hashes['native_factory_excerpt'], 'offset': '0x88e3d0'},
                ],
                'handler_class': None,
                'is_vehicle_protocol_handler': False,
                'limit': 'This path selects a native metadata table provider. It does not establish a diagnostic transport executor or a model-compatible ECU route.',
            },
            *function_edges,
            *[{
                'kind': 'native_factory_exact_key_comparison',
                'from': {'type': 'ecu_key_literal', 'value': item['ecu_key_literal']},
                'to': {'type': 'native_factory', 'elf_rva': '0x88e3d0'},
                'source': {'path': 'docs/parity/fixtures/RE-02-native-factory-key-checks.txt', 'sha256': hashes['factory_excerpt'], 'compare_call_elf_rva': item.get('comparison_call_elf_rva'), 'literal_elf_rva': item['literal_elf_rva']},
                'handler_class': None,
                'is_vehicle_protocol_handler': False,
                'limit': item['limit'],
            } for item in factory_literals if item['exactly_in_observed_68_candidate_strings']],
        ],
        'unresolved_edges': [
            {
                'kind': 'vehicle_diagid_to_protocol_or_ecu_group',
                'from': 'vehicle-records.diagid', 'to': ['ecu-groups.defaultprotocolid', 'runtime ECU key'],
                'reason': 'The raw field is retained, but no source-backed join to ECU-group protocol IDs or ECU-key strings was found.',
                'source_paths': ['assets/research/recovered-native/vehicle-records.json', 'assets/research/recovered-native/ecu-groups.json'],
            },
            {
                'kind': 'modulegroup_to_runtime_ecu_key',
                'from': 'ecu-groups.modulegroup', 'to': '68 DEX-observed key strings',
                'reason': 'No direct key/foreign-key mapping is present in recovered data or the focused loader path. Text similarity/suffixes are not used.',
                'candidate_keys': keys,
            },
            {
                'kind': 'defaultprotocolid_to_app_protocol_enum',
                'from': 'ecu-groups.defaultprotocolid values 3 and 8', 'to': 'Dart protocol enum / transport handler',
                'reason': 'Only raw group-table IDs are established; no source-backed protocol enum translation is established.',
                'raw_protocol_id_counts': dict(protocol_counts),
            },
            {
                'kind': 'FUNCTIONS_row_to_execution_handler',
                'from': 'CF_* category and jl0.b inclusion flag', 'to': 'specific executable service/coding/diagnostic handler',
                'reason': 'DEX proves category parsing and the app loader include gate, but not the implementation selected for each category/key or safe execution semantics.',
                'category_mapping': FUNCTION_ENUM,
            },
            {
                'kind': 'candidate_key_to_vehicle_compatibility',
                'from': 'candidate ECU key string', 'to': 'specific vehicle/platform compatibility',
                'reason': 'A successful table query is not physical compatibility evidence; vehicle/group-to-key edges remain unresolved.',
            },
            {
                'kind': 'legacy_130_failures_to_absent_tables',
                'from': '13 failure-only candidate keys x 10 legacy table calls', 'to': 'absence claim',
                'reason': 'The old object/vtable probe emitted invalid row counts. Only PARAMS and PARAMS_TAB_GLOBAL have the targeted private-j reclassification; remaining table actions have not been re-run via JNI. The seven JNI faults and six nulls remain explicit states, not absent features.',
                'known_failure_only_keys': [item['ecu_key'] for item in candidates if item['classification'] == 'legacy_failed_only_candidate'],
            },
            *[{'kind': 'direct_edge_validation_gap', **row} for row in unindexed_unresolved],
        ],
        'candidate_key_inventory': candidates,
        'function_type_mapping': {
            'raw_token0_to_enum_name': FUNCTION_ENUM,
            'source': {'path': 'docs/parity/fixtures/RE-02-functions-routing-excerpts.txt', 'sha256': hashes['function_excerpt']},
            'field_semantics': {
                'token0': 'Integer.parseInt; packed switch maps this numeric table ID to kl0 enum name stored as jl0.a.',
                'token1': 'Integer.parseInt; jl0.b is true iff token1 == 1, and fl0.g retains the row only when true.',
                'tokens2_to5': 'Parsed as integers in jl0 constructor but no corresponding jl0 fields are stored there; preserve as opaque raw flags.',
                'token6': 'Integer.parseInt stored as jl0.c; f40.e uses it for a localized category label via wr1.R with LNG_GENERAL.',
            },
        },
        'function_flag_summary': {
            'indexed_rows': len(function_rows), 'indexed_ecu_keys': len(function_counts),
            'retained_rows': sum(included_counts.values()), 'filtered_rows': len(function_rows)-sum(included_counts.values()),
            'raw_token1_to5_pattern_counts': dict(function_flag_patterns),
            'interpretation': 'Only the token1==1 app-list inclusion behavior is proven; other numeric columns remain raw.',
        },
        'unindexed_local_FUNCTIONS_files': unindexed_functions,
        'native_factory_literal_comparisons': factory_literals,
        'missing_direct_edges': missing_series + missing_platform_group,
    }
    out = NATIVE / 'handler-routing.json'
    out.write_text(json.dumps(artifact, ensure_ascii=False, indent=2) + '\n')
    print('Wrote', out, 'direct edges', len(direct_edges)+len(function_rows),
          'FUNCTIONS rows', len(function_rows), 'factory literal comparisons', len(factory_literals))


if __name__ == '__main__':
    main()
