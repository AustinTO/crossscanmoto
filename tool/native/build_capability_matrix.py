"""Rebuild the source-bounded vehicle/ECU capability evidence graph.

This compiles retained source rows and offline native table-probe records. It
does not infer physical compatibility from names, counts, or table presence.
"""
import hashlib
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
RESEARCH = ROOT / 'assets/research/recovered-native'
RUNTIME = RESEARCH / 'runtime-tables'
CATALOG_DART = ROOT / 'lib/diagnostics/recovered_catalog.dart'
OUTPUT = ROOT / 'assets/data/original_capability_matrix.json'
ROUTING_PATH = RESEARCH / 'handler-routing.json'
DEX_SHA256 = '869025551e5339811c300f2ae5ec92563c7e6b228d9498b8e835e2ac79283832'
TABLE_NAMES = [
    'TROUBLECODES', 'PARAMS', 'PARAMS_RES', 'PARAMS_TAB',
    'PARAMS_TAB_GLOBAL', 'ACTUATOR', 'ACTUATORPOS', 'ACTUATORCMD',
    'FUNCTIONS', 'IDENTIFICATIONS',
]
TABLE_SCOPES = {
    'DTC': ['TROUBLECODES'],
    'PARAMS': ['PARAMS', 'PARAMS_RES', 'PARAMS_TAB', 'PARAMS_TAB_GLOBAL'],
    'ACTUATOR': ['ACTUATOR', 'ACTUATORPOS', 'ACTUATORCMD'],
    'CODING': [],
    'SERVICE': ['FUNCTIONS'],
}
TABLE_SCOPE_FUNCTION_SYMBOLS = {
    'DTC': ['CF_DTCREAD', 'CF_DTCCLEAR', 'CF_INFODTCREAD', 'CF_INFODTCCLEAR'],
    'PARAMS': ['CF_LIVEDATA'],
    'ACTUATOR': ['CF_ACTORS'],
    'CODING': ['CF_CODING'],
    'SERVICE': ['CF_SERVICE'],
}
TABLE_SCOPE_BASIS = {
    'DTC': 'DEX fl0.g directly queries TROUBLECODES and parses returned rows as jj4; source-schema caller evidence only.',
    'PARAMS': 'DEX fl0.g directly queries PARAMS, PARAMS_RES, PARAMS_TAB and PARAMS_TAB_GLOBAL; relational parser joins are not a physical request proof.',
    'ACTUATOR': 'DEX fl0.g directly queries ACTUATOR, ACTUATORPOS and ACTUATORCMD with source-documented integer parent/child joins.',
    'CODING': 'No ECU-keyed coding-table/action join is established by the retained loader; unresolved.',
    'SERVICE': 'FUNCTIONS maps numeric type 12 to source name CF_SERVICE. This category label is not evidence of transport or physical support.',
}
SOURCE_FILES = [
    'assets/research/recovered-native/vehicle-records.json',
    'assets/research/recovered-native/series.json',
    'assets/research/recovered-native/ecu-groups.json',
    'assets/research/recovered-native/platform-ecu-groups.json',
    'assets/research/recovered-native/index.json',
    'assets/research/recovered-native/observed-ecu-keys.json',
    'assets/research/recovered-native/runtime-tables-index.json',
    'assets/research/recovered-native/runtime-extraction-validation.json',
    'assets/research/recovered-native/re09-jni-table-probes.json',
    'assets/research/native-schema-recovery.md',
    'assets/research/native-schema-disassembly.txt',
    'assets/research/native-data-findings.md',
    'assets/research/service-reset-recovery.md',
    'docs/parity/fixtures/RE-02-native-factory-key-checks.txt',
    'docs/parity/fixtures/RE-02-functions-routing-excerpts.txt',
    'assets/research/native-ecu-factory.asm',
    'assets/research/native-table-j.asm',
]
ROUTING_INPUT_PATHS = {
    'vehicles': 'assets/research/recovered-native/vehicle-records.json',
    'series': 'assets/research/recovered-native/series.json',
    'platform_edges': 'assets/research/recovered-native/platform-ecu-groups.json',
    'groups': 'assets/research/recovered-native/ecu-groups.json',
    'keys': 'assets/research/recovered-native/observed-ecu-keys.json',
    'index': 'assets/research/recovered-native/runtime-tables-index.json',
    'validation': 'assets/research/recovered-native/runtime-extraction-validation.json',
    'jni': 'assets/research/recovered-native/re09-jni-table-probes.json',
    'factory_excerpt': 'docs/parity/fixtures/RE-02-native-factory-key-checks.txt',
    'function_excerpt': 'docs/parity/fixtures/RE-02-functions-routing-excerpts.txt',
    'dex_schema_excerpt': 'assets/research/native-schema-disassembly.txt',
    'native_factory_excerpt': 'assets/research/native-ecu-factory.asm',
    'table_j_asm': 'assets/research/native-table-j.asm',
}
DEX_SOURCE = {
    'artifact': 'MotoScan 1.110 DEX / libmotoscan-helper.so',
    'classes_dex_sha256': '869025551e5339811c300f2ae5ec92563c7e6b228d9498b8e835e2ac79283832',
    'library_sha256': 'bab0c173bb33c37262d07bbbbdc2c91213275d2a68e941d1b39fc3affd34fc71',
    'loader_table_calls': 'assets/research/native-schema-disassembly.txt @ 0x217984-0x217e38',
    'functions_parser': 'docs/parity/fixtures/RE-02-functions-routing-excerpts.txt @ jl0 parseInt fields and packed switch 0x219902/data 0x2199bc',
    'native_factory': 'assets/research/native-data-findings.md; handler-routing.json contains focused factory evidence',
}


def read_json(name):
    return json.loads((RESEARCH / name).read_text())


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def source_ref(path, row_index=None, table_address=None):
    result = {'path': str(path.relative_to(ROOT)), 'sha256': digest(path)}
    if row_index is not None:
        result['row_index'] = row_index
    if table_address is not None:
        result['table_address'] = table_address
    return result


def dart_list(name):
    source = CATALOG_DART.read_text()
    marker = f'static const List<Map<String, String>> {name} = ['
    start = source.index(marker) + len(marker)
    end = source.index('\n];', start)
    return json.loads('[' + source[start:end] + ']')


def function_rows(ecu_key, function_type_mapping):
    path = RUNTIME / ecu_key / 'FUNCTIONS.json'
    if not path.exists():
        return None
    table = json.loads(path.read_text())
    rows = []
    for index, raw in enumerate(table['rows']):
        fields = raw.split(';')
        function_id = int(fields[0]) if fields else None
        enabled_value = int(fields[1]) if len(fields) > 1 else None
        stored_value = int(fields[6]) if len(fields) > 6 else None
        token2_to5 = fields[2:6]
        parsed_token2_to5 = [int(value) for value in token2_to5]
        category = function_type_mapping.get(str(function_id)) if function_id is not None else None
        rows.append({
            'raw': raw,
            'fields': fields,
            'function_id_token': fields[0] if fields else None,
            'enabled_token': fields[1] if len(fields) > 1 else None,
            'function_id_decoded': function_id,
            'function_category': category,
            'enabled_integer': enabled_value,
            'enabled': enabled_value == 1,
            'loader_retains_row': enabled_value == 1,
            'token2_to5_raw': token2_to5,
            'token2_to5_parsed': parsed_token2_to5,
            'stored_integer_token': fields[6] if len(fields) > 6 else None,
            'stored_integer_decoded': stored_value,
            'symbol': category,
            'symbol_status': 'source_mapped' if category else 'unresolved',
            'source': source_ref(path, index),
        })
    return {'rows': rows, 'sha256': digest(path), 'table': table}


def routing_rows(routing):
    """Preserve the source-worker's exact graph rows in the main graph."""
    rows = []
    for key in ('direct_edges', 'handler_edges', 'unresolved_edges'):
        values = routing.get(key)
        if isinstance(values, list):
            rows.extend({'edge_collection': key, **value} for value in values)
    for value in routing.get('native_factory_literal_comparisons', []):
        rows.append({'edge_collection': 'native_factory_literal_comparisons',
                     'kind': 'native_factory_literal_comparison', **value})
    return rows


def build():
    vehicle_path = RESEARCH / 'vehicle-records.json'
    series_path = RESEARCH / 'series.json'
    groups_path = RESEARCH / 'ecu-groups.json'
    platform_groups_path = RESEARCH / 'platform-ecu-groups.json'
    index_path = RESEARCH / 'runtime-tables-index.json'
    keys_path = RESEARCH / 'observed-ecu-keys.json'
    validation_path = RESEARCH / 'runtime-extraction-validation.json'

    vehicles = read_json('vehicle-records.json')
    series_document = read_json('series.json')
    groups_document = read_json('ecu-groups.json')
    platform_document = read_json('platform-ecu-groups.json')
    pointer_document = read_json('index.json')
    candidates = read_json('observed-ecu-keys.json')
    table_probes = read_json('runtime-tables-index.json')
    validation = read_json('runtime-extraction-validation.json')
    if not ROUTING_PATH.exists():
        raise FileNotFoundError(f'Required source-worker graph is missing: {ROUTING_PATH}')
    routing = json.loads(ROUTING_PATH.read_text())
    function_type_data = routing['function_type_mapping']
    function_type_mapping = function_type_data['raw_token0_to_enum_name']
    for alias, relative_path in ROUTING_INPUT_PATHS.items():
        actual_hash = digest(ROOT / relative_path)
        assert actual_hash == routing['source']['input_sha256_by_path'][alias], (
            alias, relative_path, actual_hash,
            routing['source']['input_sha256_by_path'][alias],
        )
    assert function_type_data['source']['sha256'] == digest(
        ROOT / function_type_data['source']['path']
    )
    assert routing['source']['classes_dex_sha256'] == DEX_SHA256
    assert routing['source']['library_sha256'] == validation['target_sha256']
    candidate_routing = {row['ecu_key']: row for row in routing['candidate_key_inventory']}
    assert set(candidate_routing) == set(candidates)
    function_type_ids = {
        scope: sorted(int(type_id) for type_id, category in function_type_mapping.items()
                      if category in categories)
        for scope, categories in TABLE_SCOPE_FUNCTION_SYMBOLS.items()
    }
    used_function_type_ids = {type_id for ids in function_type_ids.values() for type_id in ids}
    unmapped_function_categories = [
        {'function_type_id': int(type_id), 'category': category}
        for type_id, category in sorted(function_type_mapping.items(), key=lambda item: int(item[0]))
        if int(type_id) not in used_function_type_ids
    ]

    # Verify the checked-in Dart catalog is the same retained source inventory.
    assert dart_list('vehicles') == vehicles
    assert dart_list('series') == series_document['records']
    assert dart_list('ecuGroups') == groups_document['records']
    assert dart_list('platformEcuGroups') == platform_document['records']
    assert len(vehicles) == 84 and len(series_document['records']) == 7
    assert len(groups_document['records']) == 29
    assert len(platform_document['records']) == 49
    assert len(candidates) == 68
    assert validation['validated_nonempty_tables'] == 234
    assert validation['validated_rows'] == 8017
    assert validation['failed_probes'] == 130

    series_by_id = {row['id']: row for row in series_document['records']}
    groups_by_id = {row['id']: row for row in groups_document['records']}
    for vehicle in vehicles:
        assert vehicle['car_seriesid'] in series_by_id
    for edge in platform_document['records']:
        assert edge['ecu_groupsid'] in groups_by_id

    probe_by_key_table = {(row['key'], row['table']): row for row in table_probes}
    assert len(probe_by_key_table) == len(table_probes)
    successful_keys = sorted({row['key'] for row in table_probes if 'row_count' in row})
    assert len(successful_keys) == 55
    failed_rows = [row for row in table_probes if 'row_count' not in row]
    assert len(failed_rows) == 130
    assert set(successful_keys) | {row['key'] for row in failed_rows} <= set(candidates)
    assert len(candidates) * len(TABLE_NAMES) == 680
    assert len(table_probes) == 364
    assert len(candidates) * len(TABLE_NAMES) - len(table_probes) == 316

    supplemental_functions = []
    indexed_pairs = set(probe_by_key_table)
    for path in sorted(RUNTIME.glob('*/FUNCTIONS.json')):
        ecu_key = path.parent.name
        if (ecu_key, 'FUNCTIONS') in indexed_pairs:
            continue
        table_data = json.loads(path.read_text())
        rows = []
        for row_index, raw in enumerate(table_data['rows']):
            fields = raw.split(';')
            function_id = int(fields[0]) if fields else None
            enabled_value = int(fields[1]) if len(fields) > 1 else None
            stored_value = int(fields[6]) if len(fields) > 6 else None
            category = function_type_mapping.get(str(function_id)) if function_id is not None else None
            rows.append({
                'raw': raw, 'fields': fields,
                'function_id_token': fields[0] if fields else None,
                'enabled_token': fields[1] if len(fields) > 1 else None,
                'function_id_decoded': function_id,
                'function_category': category,
                'enabled_integer': enabled_value,
                'enabled': enabled_value == 1,
                'loader_retains_row': enabled_value == 1,
                'token2_to5_raw': fields[2:6],
                'token2_to5_parsed': [int(value) for value in fields[2:6]],
                'stored_integer_token': fields[6] if len(fields) > 6 else None,
                'stored_integer_decoded': stored_value,
                'symbol': category,
                'symbol_status': 'source_mapped' if category else 'unresolved',
                'source': source_ref(path, row_index),
            })
        supplemental_functions.append({
            'ecu_key': ecu_key,
            'status': 'supplemental_unindexed_native_table_file',
            'probe_result': 'unrecorded; no runtime-tables-index.json outcome row',
            'rows': rows,
            'file_sha256': digest(path),
            'capture_sha256': table_data['sha256'],
            'source': source_ref(path),
        })
    assert len(supplemental_functions) == 5
    assert {row['ecu_key'] for row in supplemental_functions} == {
        'cuMRDWA', 'cuMRABS', 'cuMRRBT', 'cuMRMA24', 'cuMRRDC'
    }

    routes = routing_rows(routing)

    sources = {name: source_ref(ROOT / name) for name in SOURCE_FILES}
    sources['recovered_catalog.dart'] = source_ref(CATALOG_DART)
    sources['handler-routing.json'] = source_ref(ROUTING_PATH)
    sources['function_type_mapping'] = source_ref(
        ROOT / function_type_data['source']['path']
    )
    sources['runtime_tables'] = {
        'root': 'assets/research/recovered-native/runtime-tables/',
        'library_sha256': pointer_document['source_sha256'],
        'status': 'per-table path, stdout hash, file hash, rows, and probe status retained below',
    }
    for path in ('assets/research/native-schema-recovery.md',
                 'assets/research/native-schema-disassembly.txt',
                 'assets/research/native-data-findings.md',
                 'assets/research/service-reset-recovery.md'):
        assert sources[path]['sha256']
    sources['supplemental_unindexed_FUNCTIONS_files'] = [
        {'ecu_key': row['ecu_key'], **row['source'],
         'capture_sha256': row['capture_sha256'], 'row_count': len(row['rows'])}
        for row in supplemental_functions
    ]

    # The source worker's graph contains the source-hashed canonical direct
    # edges, including vehicle/platform/group rows, FUNCTION flags and handlers.
    edges = []
    for index, vehicle in enumerate(vehicles):
        record_pointer = pointer_document['records'][index + 1]
        pointer_fields = pointer_document['records'][0]['fields']
        pointer_row = {
            header['preview']: field['preview']
            for header, field in zip(pointer_fields, record_pointer['fields'])
        }
        assert pointer_row == vehicle, f'vehicle pointer row mismatch at index {index}'
    edges.extend({'kind': row.get('kind', row.get('edge_collection')),
                  'source_artifact': 'handler-routing.json', **row}
                 for row in routes)

    ecu_nodes = []
    all_actions = []
    for candidate_index, ecu_key in enumerate(candidates):
        function_data = function_rows(ecu_key, function_type_mapping)
        key_probes = []
        for table in TABLE_NAMES:
            probe = probe_by_key_table.get((ecu_key, table))
            table_path = RUNTIME / ecu_key / f'{table}.json'
            if probe is None:
                row = {'key': ecu_key, 'table': table, 'status': 'unrecorded'}
            elif 'row_count' in probe:
                table_data = json.loads(table_path.read_text())
                assert table_data['ecu_key'] == ecu_key
                assert table_data['table'] == table
                assert len(table_data['rows']) == probe['row_count']
                assert table_data['sha256'] == probe['sha256']
                row = {
                    **probe, 'status': 'returned_rows',
                    'probe_generation': 'offline_native_table_probe',
                    'source_row': probe,
                    'source_row_index': table_probes.index(probe),
                    'table_file_sha256': digest(table_path),
                    'source_rows_included': table == 'FUNCTIONS',
                }
            else:
                row = {
                    **probe, 'status': 'legacy_probe_failed',
                    'probe_generation': 'offline_native_table_probe',
                    'source_row': probe,
                    'source_row_index': table_probes.index(probe),
                }
            if table in ('PARAMS', 'PARAMS_TAB_GLOBAL'):
                row['secondary_private_j_probe'] = candidate_routing[ecu_key].get(
                    're09_private_j_status', {}
                ).get(table)
                row['secondary_private_j_source'] = 'assets/research/recovered-native/re09-jni-table-probes.json'
            key_probes.append(row)
            all_actions.append(row)

        funcs = function_data['rows'] if function_data else []
        function_probe = probe_by_key_table.get((ecu_key, 'FUNCTIONS'))
        if function_probe is not None and 'row_count' in function_probe:
            assert function_data is not None
        if function_data is not None and function_probe is None:
            raise AssertionError(f'unindexed candidate FUNCTIONS file: {ecu_key}')
        if function_data is not None and function_probe is not None:
            assert len(funcs) == function_probe['row_count']
            assert function_data['table']['sha256'] == function_probe['sha256']
        ecu_nodes.append({
            'ecu_key': ecu_key,
            'candidate_index': candidate_index,
            'candidate_source': source_ref(keys_path, candidate_index),
            'runtime_observed_key': ecu_key in successful_keys,
            'functions_table': {
                'status': 'returned_rows' if function_data and function_probe and 'row_count' in function_probe
                else 'probe_failed' if function_probe is not None and 'row_count' not in function_probe
                else 'unrecorded',
                'rows': funcs,
                'file_sha256': function_data['sha256'] if function_data else None,
            },
            'handler_routing_candidate': candidate_routing[ecu_key],
            'function_flag_interpretation': {
                'field_semantics': function_type_data['field_semantics'],
                'type_mapping': function_type_mapping,
                'mapping_source': function_type_data['source'],
            },
            'table_probe_rows': key_probes,
        })

    for ecu in ecu_nodes:
        for probe in ecu['table_probe_rows']:
            edges.append({
                'kind': 'ecu_to_native_table_action',
                'from': ecu['ecu_key'], 'to': probe['table'],
                'status': probe['status'],
                'source_probe_row': probe if probe['status'] != 'unrecorded' else None,
                'source': source_ref(index_path),
                'interpretation': 'offline source-table probe only; not physical capability',
            })
    for table in supplemental_functions:
        for row in table['rows']:
            edges.append({
                'kind': 'supplemental_ecu_to_FUNCTIONS_flag',
                'from': table['ecu_key'], 'to': row['function_id_decoded'],
                'raw_row': row['raw'], 'enabled': row['enabled'],
                'source': row['source'],
                'status': 'supplemental_unindexed_native_table_file',
            })
    edges.append({
        'kind': 'unresolved_CODING_scope', 'from': 'CODING', 'to': None,
        'status': 'unresolved',
        'reason': 'Retained loader and native table probe inventory establish no ECU-keyed coding table/action join.',
        'evidence': 'assets/research/native-schema-recovery.md; assets/research/native-data-findings.md',
        'compatibility_claim': False,
    })

    scope_actions = []
    for ecu in ecu_nodes:
        for scope, tables in TABLE_SCOPES.items():
            scope_actions.append({
                'ecu_key': ecu['ecu_key'],
                'scope': scope,
                'table_names': tables,
                'scope_basis': TABLE_SCOPE_BASIS[scope],
                'table_statuses': [
                    {'table': row['table'], 'status': row['status'],
                     'row_count': row.get('row_count'), 'stdout_sha256': row.get('sha256'),
                     'error': row.get('error'),
                     'secondary_private_j_probe': row.get('secondary_private_j_probe')}
                    for row in ecu['table_probe_rows'] if row['table'] in tables
                ],
                'function_flag_association': {
                    'status': 'mapped_by_source_category_name',
                    'function_type_ids': function_type_ids[scope],
                    'categories': TABLE_SCOPE_FUNCTION_SYMBOLS[scope],
                    'source': function_type_data['source'],
                    'basis': 'Exact FUNCTIONS numeric-type mapping from the DEX switch; names classify UI function categories, not vehicle compatibility.',
                    'rows': [
                        {
                            'raw': row['raw'],
                            'function_type_id': row['function_id_decoded'],
                            'category': row['function_category'],
                            'enabled': row['enabled'],
                            'loader_retains_row': row['loader_retains_row'],
                        }
                        for row in ecu['functions_table']['rows']
                        if row['function_id_decoded'] in function_type_ids[scope]
                    ],
                },
                'coding_status': (
                    'unresolved: no coding table/API join established by recovered loader'
                    if scope == 'CODING' else None
                ),
                'compatibility_claim': False,
            })

    source_document = {
        'artifact': 'MotoScan 1.110 native database and DEX caller evidence',
        'native_library_sha256': pointer_document['source_sha256'],
        'dex_evidence': DEX_SOURCE,
        'native_probe_run': {
            'source_sha256': validation['probe_source_sha256'],
            'binary_sha256': validation['probe_binary_sha256'],
            'emulator_version': validation['emulator_version'],
            'checks': validation['checks'],
            'limits': validation['limits'],
        },
        'sources': sources,
        'function_type_mapping': function_type_data,
        'function_flag_summary': routing['function_flag_summary'],
        'action_function_type_ids': function_type_ids,
        'unmapped_function_categories': unmapped_function_categories,
        'evidence_limits': [
            'Native table execution was offline using a custom loader; it is not an original Android or vehicle execution.',
            'A failed native probe is unresolved evidence, not proof that a table or ECU is absent.',
            'All 130 legacy probe errors remain preserved; the targeted private-JNI reprobe is separately attached only to PARAMS and PARAMS_TAB_GLOBAL actions.',
            'Table presence and FUNCTIONS flags are not physical compatibility or permission to execute an action.',
            'Database protocol ids remain raw values and are not equated with client protocol enum ordinals.',
            'Vehicle diagid and ECU group defaultprotocolid are retained as distinct raw fields unless a source edge proves a join.',
            'FUNCTIONS categories are UI visibility flags, not proof that a corresponding request handler is supported or safe for a vehicle.',
            'CF_SERVICE_FUNCTIONS (type 11) remains a distinct category from CF_SERVICE (type 12); it is not merged into SERVICE actions.',
            'The older service-reset note maps type 8 to CF_SERVICE; the primary switch excerpt maps type 8 to CF_ADAPTIONS and type 12 to CF_SERVICE. The older claim is not used.',
        ],
        'source_conflicts': [{
            'path': 'assets/research/service-reset-recovery.md',
            'claim': 'FUNCTIONS type 8 is CF_SERVICE',
            'status': 'superseded_by_primary_switch_excerpt',
            'corrected_mapping': {
                '8': function_type_mapping['8'],
                '12': function_type_mapping['12'],
            },
            'authority': function_type_data['source'],
            'action': 'Do not gate SERVICE using type 8; type 8 is ADAPTIONS and type 12 is SERVICE.',
        }],
    }
    return {
        'schema_version': 1,
        'classification': 'SOURCE_DERIVED_EVIDENCE_MATRIX; not physical compatibility certification',
        'source': source_document,
        'counts': {
            'vehicle_rows': len(vehicles), 'series_rows': len(series_document['records']),
            'ecu_group_rows': len(groups_document['records']),
            'platform_group_rows': len(platform_document['records']),
            'candidate_ecu_keys': len(candidates), 'runtime_observed_ecu_keys': len(successful_keys),
            'nonempty_native_table_probes': validation['validated_nonempty_tables'],
            'validated_native_row_occurrences': validation['validated_rows'],
            'failed_native_table_probes': validation['failed_probes'],
            'legacy_failure_only_candidates': sum(
                row['handler_routing_candidate']['classification'] == 'legacy_failed_only_candidate'
                for row in ecu_nodes
            ),
            'unrecorded_candidate_table_pairs': len(all_actions) - len(table_probes),
            'table_probe_pairs_represented': len(all_actions),
            'function_flag_rows': (
                sum(len(row['functions_table']['rows']) for row in ecu_nodes)
                + sum(len(row['rows']) for row in supplemental_functions)
            ),
            'indexed_function_flag_rows': routing['function_flag_summary']['indexed_rows'],
            'function_rows_retained_by_loader': routing['function_flag_summary']['retained_rows'],
            'function_rows_filtered_by_loader': routing['function_flag_summary']['filtered_rows'],
            'routing_direct_edges': len(routing['direct_edges']),
            'routing_handler_edges': len(routing['handler_edges']),
            'routing_unresolved_edge_classes': len(routing['unresolved_edges']),
            'factory_literal_comparisons': len(routing['native_factory_literal_comparisons']),
        },
        'nodes': {
            'vehicles': [
                {'raw_row': row, 'source': source_ref(vehicle_path, i),
                 'pointer_record': pointer_document['records'][i + 1]}
                for i, row in enumerate(vehicles)
            ],
            'series': [
                {'raw_row': row, 'source': source_ref(series_path, i,
                                                      series_document['table_address'])}
                for i, row in enumerate(series_document['records'])
            ],
            'ecu_groups': [
                {'raw_row': row, 'source': source_ref(groups_path, i,
                                                      groups_document['table_address'])}
                for i, row in enumerate(groups_document['records'])
            ],
            'ecu_candidates': ecu_nodes,
        },
        'edges': edges,
        'table_actions': scope_actions,
        'native_table_probe_rows': all_actions,
        'supplemental_function_tables': supplemental_functions,
        'handler_routing_evidence': {
            'path': sources['handler-routing.json']['path'],
            'sha256': sources['handler-routing.json']['sha256'],
            'schema_version': routing['schema_version'],
            'source': routing['source'],
            'counts': routing['source']['counts'],
            'missing_direct_edges': routing['missing_direct_edges'],
            'contains_full_rows': False,
            'full_source_hashed_edges_in_graph': True,
        },
    }


def main():
    artifact = build()
    OUTPUT.write_text(json.dumps(artifact, ensure_ascii=False, separators=(',', ':')) + '\n')
    print('Wrote capability evidence matrix:', artifact['counts'])


if __name__ == '__main__':
    main()
