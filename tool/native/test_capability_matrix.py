"""Independent inventory/source checks for the RE-02 capability graph."""
import json
import hashlib
import subprocess
import sys
import unittest
from collections import Counter
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
RESEARCH = ROOT / 'assets/research/recovered-native'
MATRIX = ROOT / 'assets/data/original_capability_matrix.json'
BUILDER = ROOT / 'tool/native/build_capability_matrix.py'
TABLE_NAMES = {
    'TROUBLECODES', 'PARAMS', 'PARAMS_RES', 'PARAMS_TAB', 'PARAMS_TAB_GLOBAL',
    'ACTUATOR', 'ACTUATORPOS', 'ACTUATORCMD', 'FUNCTIONS', 'IDENTIFICATIONS',
}


class CapabilityMatrixTests(unittest.TestCase):
    def test_matrix_retains_independent_source_rows_and_probe_outcomes(self):
        matrix = json.loads(MATRIX.read_text())
        vehicles = json.loads((RESEARCH / 'vehicle-records.json').read_text())
        series = json.loads((RESEARCH / 'series.json').read_text())
        groups = json.loads((RESEARCH / 'ecu-groups.json').read_text())
        platform_groups = json.loads((RESEARCH / 'platform-ecu-groups.json').read_text())
        candidates = json.loads((RESEARCH / 'observed-ecu-keys.json').read_text())
        probes = json.loads((RESEARCH / 'runtime-tables-index.json').read_text())
        routing = json.loads((RESEARCH / 'handler-routing.json').read_text())
        pointer_table = json.loads((RESEARCH / 'index.json').read_text())
        validation = json.loads((RESEARCH / 'runtime-extraction-validation.json').read_text())

        self.assertEqual(matrix['counts']['vehicle_rows'], len(vehicles))
        self.assertEqual(matrix['counts']['series_rows'], len(series['records']))
        self.assertEqual(matrix['counts']['ecu_group_rows'], len(groups['records']))
        self.assertEqual(matrix['counts']['platform_group_rows'], len(platform_groups['records']))
        self.assertEqual(len(vehicles), 84)
        self.assertEqual(len(series['records']), 7)
        self.assertEqual(len(groups['records']), 29)
        self.assertEqual(len(platform_groups['records']), 49)

        matrix_vehicles = matrix['nodes']['vehicles']
        self.assertEqual([node['raw_row'] for node in matrix_vehicles], vehicles)
        self.assertEqual(len({vehicle['id'] for vehicle in vehicles}), 84)
        headers = pointer_table['records'][0]['fields']
        for index, node in enumerate(matrix_vehicles):
            fields = node['pointer_record']['fields']
            reconstructed = {header['preview']: field['preview']
                             for header, field in zip(headers, fields)}
            self.assertEqual(reconstructed, vehicles[index])
        self.assertEqual(
            [node['raw_row'] for node in matrix['nodes']['series']], series['records']
        )
        self.assertEqual(
            [node['raw_row'] for node in matrix['nodes']['ecu_groups']], groups['records']
        )
        self.assertEqual(
            [edge['raw_row'] for edge in matrix['edges'] if edge['kind'] == 'platform_to_ecu_group'],
            platform_groups['records'],
        )
        expected_candidate_keys = set(candidates)
        matrix_ecus = matrix['nodes']['ecu_candidates']
        self.assertEqual({node['ecu_key'] for node in matrix_ecus}, expected_candidate_keys)
        self.assertEqual(len(expected_candidate_keys), 68)

        indexed = {(probe['key'], probe['table']): probe for probe in probes}
        indexed_order = {(probe['key'], probe['table']): index
                         for index, probe in enumerate(probes)}
        matrix_probe_rows = matrix['native_table_probe_rows']
        self.assertEqual(len(matrix_probe_rows), 68 * len(TABLE_NAMES))
        self.assertEqual(matrix['counts']['table_probe_pairs_represented'], 680)
        self.assertEqual(matrix['counts']['nonempty_native_table_probes'], 234)
        self.assertEqual(matrix['counts']['runtime_observed_ecu_keys'], 55)
        self.assertEqual(matrix['counts']['failed_native_table_probes'], 130)
        self.assertEqual(matrix['counts']['legacy_failure_only_candidates'], 13)
        self.assertEqual(matrix['counts']['unrecorded_candidate_table_pairs'], 316)
        self.assertEqual(matrix['counts']['validated_native_row_occurrences'], 8017)
        self.assertEqual(validation['failed_probes'], 130)

        observed_keys = set()
        failed_pairs = set()
        outcome_counts = Counter()
        for row in matrix_probe_rows:
            pair = (row['key'], row['table'])
            self.assertIn(row['table'], TABLE_NAMES)
            source = indexed.get(pair)
            if source is None:
                self.assertEqual(row['status'], 'unrecorded')
                outcome_counts['unrecorded'] += 1
            elif 'row_count' in source:
                self.assertEqual(row['status'], 'returned_rows')
                self.assertEqual(row['source_row'], source)
                self.assertEqual(row['source_row_index'], indexed_order[pair])
                self.assertEqual(row['row_count'], source['row_count'])
                self.assertEqual(row['sha256'], source['sha256'])
                table_path = RESEARCH / 'runtime-tables' / row['key'] / f"{row['table']}.json"
                table = json.loads(table_path.read_text())
                self.assertEqual(len(table['rows']), source['row_count'])
                self.assertEqual(table['sha256'], source['sha256'])
                self.assertEqual(
                    row['table_file_sha256'],
                    hashlib.sha256(table_path.read_bytes()).hexdigest(),
                )
                observed_keys.add(row['key'])
                outcome_counts['returned_rows'] += 1
            else:
                self.assertEqual(row['status'], 'legacy_probe_failed')
                self.assertEqual(row['source_row'], source)
                self.assertEqual(row['source_row_index'], indexed_order[pair])
                self.assertEqual(row['error'], source['error'])
                failed_pairs.add(pair)
                outcome_counts['legacy_probe_failed'] += 1
            if row['table'] in ('PARAMS', 'PARAMS_TAB_GLOBAL'):
                candidate = next(item for item in routing['candidate_key_inventory']
                                 if item['ecu_key'] == row['key'])
                self.assertEqual(
                    row['secondary_private_j_probe'],
                    candidate['re09_private_j_status'][row['table']],
                )
        self.assertEqual(len(observed_keys), 55)
        self.assertEqual(failed_pairs, {
            (row['key'], row['table']) for row in probes if 'row_count' not in row
        })
        self.assertEqual(outcome_counts, {
            'returned_rows': 234, 'legacy_probe_failed': 130, 'unrecorded': 316,
        })
        failed_keys = {key for key, _ in failed_pairs}
        self.assertEqual(len(failed_keys), 13)
        self.assertEqual(failed_keys, expected_candidate_keys - observed_keys)

        # DEX-identified service feature flag and five supplemental FUNCTION
        # captures must not be silently folded into the 68-candidate set.
        self.assertEqual({row['ecu_key'] for row in matrix['supplemental_function_tables']}, {
            'cuMRDWA', 'cuMRABS', 'cuMRRBT', 'cuMRMA24', 'cuMRRDC',
        })
        self.assertEqual(len(matrix['supplemental_function_tables']), 5)
        function_row_count = 0
        for node in matrix_ecus:
            path = RESEARCH / 'runtime-tables' / node['ecu_key'] / 'FUNCTIONS.json'
            if path.exists():
                source_rows = json.loads(path.read_text())['rows']
                self.assertEqual(
                    [row['raw'] for row in node['functions_table']['rows']], source_rows
                )
                function_row_count += len(source_rows)
            else:
                self.assertEqual(node['functions_table']['rows'], [])
        for supplemental in matrix['supplemental_function_tables']:
            path = RESEARCH / 'runtime-tables' / supplemental['ecu_key'] / 'FUNCTIONS.json'
            source_rows = json.loads(path.read_text())['rows']
            self.assertEqual([row['raw'] for row in supplemental['rows']], source_rows)
            function_row_count += len(source_rows)
        self.assertEqual(matrix['counts']['function_flag_rows'], function_row_count)
        for supplemental in matrix['supplemental_function_tables']:
            table_path = RESEARCH / 'runtime-tables' / supplemental['ecu_key'] / 'FUNCTIONS.json'
            self.assertTrue(table_path.stat().st_size > 0)
            self.assertEqual(
                hashlib.sha256(table_path.read_bytes()).hexdigest(),
                supplemental['file_sha256'],
            )
        flag_row = next(
            row for node in matrix_ecus if node['ecu_key'] == 'cuX_BMSX'
            for row in node['functions_table']['rows'] if row['raw'] == '8;1;0;0;0;0;49659'
        )
        self.assertEqual(flag_row['symbol'], 'CF_ADAPTIONS')
        self.assertTrue(flag_row['enabled'])
        self.assertEqual(flag_row['symbol_status'], 'source_mapped')
        self.assertEqual(matrix['source']['function_type_mapping']['raw_token0_to_enum_name']['12'],
                         'CF_SERVICE')
        self.assertEqual(matrix['source']['function_type_mapping']['raw_token0_to_enum_name']['8'],
                         'CF_ADAPTIONS')
        expected_scope_type_ids = {
            'DTC': [2, 3, 14, 15], 'PARAMS': [5], 'ACTUATOR': [6],
            'CODING': [7], 'SERVICE': [12],
        }
        ecu_nodes_by_key = {node['ecu_key']: node for node in matrix_ecus}
        for action in matrix['table_actions']:
            self.assertEqual(action['function_flag_association']['status'],
                             'mapped_by_source_category_name')
            self.assertEqual(
                action['function_flag_association']['function_type_ids'],
                expected_scope_type_ids[action['scope']],
            )
            source_function_rows = ecu_nodes_by_key[action['ecu_key']]['functions_table']['rows']
            expected_flag_rows = [
                {
                    'raw': row['raw'],
                    'function_type_id': row['function_id_decoded'],
                    'category': row['function_category'],
                    'enabled': row['enabled'],
                    'loader_retains_row': row['loader_retains_row'],
                }
                for row in source_function_rows
                if row['function_id_decoded'] in expected_scope_type_ids[action['scope']]
            ]
            self.assertEqual(
                action['function_flag_association']['rows'], expected_flag_rows
            )
            self.assertEqual(
                action['function_flag_association']['source'],
                routing['function_type_mapping']['source'],
            )
        self.assertEqual(matrix['source']['source_conflicts'][0]['corrected_mapping'],
                         {'8': 'CF_ADAPTIONS', '12': 'CF_SERVICE'})
        self.assertEqual(matrix['handler_routing_evidence']['sha256'],
                         hashlib.sha256((RESEARCH / 'handler-routing.json').read_bytes()).hexdigest())
        self.assertEqual(
            matrix['handler_routing_evidence']['source']['dex_offsets']['jl0 numeric function-type switch'],
            '0x219902, packed switch data 0x2199bc',
        )
        self.assertEqual(matrix['counts']['routing_direct_edges'], 777)
        self.assertEqual(matrix['counts']['routing_handler_edges'], 398)
        self.assertEqual(matrix['counts']['routing_unresolved_edge_classes'], 6)
        self.assertEqual(matrix['counts']['factory_literal_comparisons'], 30)
        self.assertEqual(
            matrix['source']['function_flag_summary'], routing['function_flag_summary']
        )
        route_collections = {
            'direct_edges': routing['direct_edges'],
            'handler_edges': routing['handler_edges'],
            'unresolved_edges': routing['unresolved_edges'],
        }
        for collection, expected_rows in route_collections.items():
            actual_rows = [
                {key: value for key, value in edge.items()
                 if key not in ('source_artifact', 'edge_collection')}
                for edge in matrix['edges'] if edge.get('edge_collection') == collection
            ]
            self.assertEqual(actual_rows, expected_rows)
        self.assertEqual(
            {row['kind'] for row in matrix['edges']
             if row.get('edge_collection') == 'unresolved_edges'},
            {row['kind'] for row in routing['unresolved_edges']},
        )
        indexed_function_rows = [
            row for row in probes
            if row['table'] == 'FUNCTIONS' and 'row_count' in row
        ]
        raw_flags = []
        for probe in indexed_function_rows:
            rows = json.loads(
                (RESEARCH / 'runtime-tables' / probe['key'] / 'FUNCTIONS.json').read_text()
            )['rows']
            raw_flags.extend(rows)
        retained = sum(int(row.split(';')[1]) == 1 for row in raw_flags)
        self.assertEqual(len(raw_flags), 389)
        self.assertEqual(retained, 243)
        self.assertEqual(len(raw_flags) - retained, 146)
        self.assertFalse(any(action['compatibility_claim'] for action in matrix['table_actions']))
        self.assertEqual(
            {action['scope'] for action in matrix['table_actions']},
            {'DTC', 'PARAMS', 'ACTUATOR', 'CODING', 'SERVICE'},
        )
        self.assertTrue(all('unresolved' in action['coding_status']
                            for action in matrix['table_actions'] if action['scope'] == 'CODING'))

    def test_builder_is_reproducible(self):
        expected = MATRIX.read_bytes()
        for _ in range(2):
            subprocess.run(
                [sys.executable, str(BUILDER)], cwd=ROOT, check=True,
                stdout=subprocess.PIPE, stderr=subprocess.PIPE,
            )
            self.assertEqual(MATRIX.read_bytes(), expected)


if __name__ == '__main__':
    unittest.main()
