"""Provenance, membership, and deterministic-generation checks for RE-09."""
import hashlib
import json
import subprocess
import sys
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
FIXTURE = ROOT / 'test/fixtures/params_number_layout_goldens.json'
BUILDER = ROOT / 'tool/native/build_parameter_goldens.py'
TABLES = ROOT / 'assets/research/recovered-native/runtime-tables'


class ParameterGoldenTests(unittest.TestCase):
    def test_every_static_vector_has_actual_catalog_membership_and_provenance(self):
        fixture = json.loads(FIXTURE.read_text())
        catalog = json.loads(
            (ROOT / 'assets/data/recovered_uds_parameters.json').read_text()
        )
        self.assertIn('STATIC_GOLDEN', fixture['source']['classification'])
        display_oracle = fixture['source']['display_oracle']
        self.assertEqual(display_oracle['locale'], 'en-US')
        self.assertEqual(
            display_oracle['harness_sha256'],
            hashlib.sha256((ROOT / 'tool/native/NumberFormatOracle.java').read_bytes()).hexdigest(),
        )
        cases = fixture['cases']
        keys = set()
        catalog_keys = set()
        for ecu, parameters in catalog.items():
            for parameter in parameters:
                for result in parameter['results']:
                    if result['raw'].split(';')[3] == '1':
                        catalog_keys.add((ecu, parameter['raw'], result['raw']))
        vectors = {}
        for case in cases:
            ecu = case['ecu_key']
            key = (ecu, case['parameter_raw'], case['result_raw'])
            keys.add(key)
            vectors.setdefault(key, []).append(case)
            self.assertIn(ecu, catalog)
            parents = [
                row for row in catalog[ecu]
                if row['raw'] == case['parameter_raw']
            ]
            self.assertEqual(len(parents), 1)
            self.assertTrue(any(row['raw'] == case['result_raw'] for row in parents[0]['results']))
            fields = case['result_raw'].split(';')
            self.assertEqual(fields[3], '1')
            self.assertEqual(case['provenance']['kind'], 'ACTUAL_NATIVE_ROW')
            self.assertEqual(case['provenance']['ecu_key'], ecu)
            self.assertEqual(case['provenance']['dex_sha256'], fixture['source']['dex_sha256'])
            self.assertEqual(
                case['provenance']['dex_offsets'],
                {
                    'number_decode': 'j21.b @ 0x26c610-0x26c62a',
                    'numeric_dispatch': 'ob2.D @ 0x31d9a4-0x31db8c',
                    'big_endian': 'ob2.D @ 0x31d9b4-0x31d9c0',
                    'response_bounds': 'j21.b @ 0x26c25c-0x26c282',
                    'response_prefix': 'sl0.p @ 0x21f59a-0x21f5c4',
                },
            )
            for table, field in (('PARAMS', 'parameter_raw'), ('PARAMS_RES', 'result_raw')):
                path = TABLES / ecu / f'{table}.json'
                data = json.loads(path.read_text())
                self.assertIn(case[field], data['rows'])
                self.assertEqual(
                    hashlib.sha256(path.read_bytes()).hexdigest(),
                    case['provenance'][f'{table.lower()}_file_sha256'],
                )
                self.assertEqual(
                    data['sha256'],
                    case['provenance'][f'{table.lower()}_capture_sha256'],
                )
            self.assertEqual(case['provenance']['kind'], 'ACTUAL_NATIVE_ROW')
            self.assertEqual(case['base_offset'], 3)
            self.assertEqual(case['absolute_value_offset'], 3 + int(fields[7]))
            self.assertIsInstance(case['expected_display'], str)
            response = case['response_full']
            parameter_fields = case['parameter_raw'].split(';')
            did = [int(token, 16) for token in parameter_fields[1].split(',')]
            self.assertEqual(response[:3], [0x62, *did[1:]])

        self.assertEqual(len(keys), 268)
        self.assertEqual(keys, catalog_keys)
        self.assertEqual(len(cases), 804)
        expected_variants = {
            'zero', 'signed_boundary', 'unsigned_max',
            'positive_max', 'negative_min', 'negative_one',
        }
        for group in vectors.values():
            self.assertEqual(len(group), 3)
            variants = {case['variant'] for case in group}
            self.assertEqual(len(variants), 3)
            self.assertTrue(variants <= expected_variants)

    def test_generator_is_deterministic(self):
        original = FIXTURE.read_bytes()
        for _ in range(2):
            subprocess.run(
                [sys.executable, str(BUILDER)], cwd=ROOT, check=True,
                stdout=subprocess.PIPE, stderr=subprocess.PIPE,
            )
            self.assertEqual(FIXTURE.read_bytes(), original)


if __name__ == '__main__':
    unittest.main()
