"""Regression tests for the evidence-bounded parameter catalog builder."""
import json
import hashlib
import tempfile
import unittest
from pathlib import Path

from build_parameter_catalog import compile_catalog


class ParameterCatalogTests(unittest.TestCase):
    def test_original_fixture_rows_and_provenance_match_retained_captures(self):
        root = Path(__file__).resolve().parents[2]
        fixture = json.loads((root / 'test/fixtures/params_number_goldens.json').read_text())
        for case in fixture['cases']:
            provenance = case.get('provenance', {})
            if provenance.get('kind') != 'ACTUAL_NATIVE_ROW':
                continue
            for table, field in [('PARAMS', 'parameter_raw'), ('PARAMS_RES', 'result_raw')]:
                path = root / 'assets/research/recovered-native/runtime-tables' / provenance['ecu_key'] / f'{table}.json'
                data = json.loads(path.read_text())
                self.assertIn(case[field], data['rows'])
                self.assertEqual(hashlib.sha256(path.read_bytes()).hexdigest(), provenance[f'{table.lower()}_file_sha256'])
                self.assertEqual(data['sha256'], provenance[f'{table.lower()}_capture_sha256'])

    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.root = Path(self.temp.name) / 'tables'
        self.root.mkdir()
        self.texts = Path(self.temp.name) / 'texts.ndjson'
        self.texts.write_text(json.dumps({
            'id': 105412, 'method': 't', 'text': 'Display label',
        }) + '\n')
        self.units = Path(self.temp.name) / 'units.txt'
        self.units.write_text('id;description;languageid\n7;°C;105482\n')

    def tearDown(self):
        self.temp.cleanup()

    def table(self, ecu, name, rows):
        folder = self.root / ecu
        folder.mkdir(exist_ok=True)
        (folder / f'{name}.json').write_text(json.dumps({'ecu_key': ecu, 'rows': rows}))

    def test_attaches_only_matching_ecu_result_rows_and_preserves_unresolved(self):
        # Original-derived row shapes: PARAMS token 0 is j21.a and
        # PARAMS_RES token 1 is k21.b (DEX fl0.g @ 0x217a80-0x217aa8).
        # Ll21 token 1 is its decoded join key to the PARAMS_RES token 0.
        self.table('ecu_a', 'PARAMS', ['21;22,62,00;TEMP;3;0;105969;1;0'])
        self.table('ecu_a', 'PARAMS_RES', [
            '173;21;TEMP_VALUE;1;7;high;signed int;0;2;;1;1;1;0;105412;1;0',
            '174;21;TEMP_UNIT;1;7;high;unsigned char;0;1;;1;1;1;0;999999;1;0',
        ])
        self.table('ecu_a', 'PARAMS_TAB', ['900;173;0;105437', '901;99;also;retained'])
        self.table('ecu_a', 'PARAMS_TAB_GLOBAL', ['unresolved;global;row'])
        self.table('ecu_b', 'PARAMS', ['21;22,63,01;SPEED;3;0;105970;1;0'])
        self.table('ecu_b', 'PARAMS_RES', ['174;99;OTHER;1;7;high;signed int;0;2'])

        catalog = compile_catalog(self.root, self.texts, self.units)
        row_a = catalog['ecu_a'][0]
        row_b = catalog['ecu_b'][0]
        self.assertEqual(row_a['did'], 0x6200)
        self.assertEqual(row_a['results'], [{
            'raw': '173;21;TEMP_VALUE;1;7;high;signed int;0;2;;1;1;1;0;105412;1;0',
            'label_id': 105412,
            'label': 'Display label',
            'label_source': 'native_t',
            'unit_id': 7,
            'unit': '',
            'tabs': [{
                'raw': '900;173;0;105437',
                'text_id': 105437,
                'text': 'unknown text',
                'text_source': 'native_placeholder',
            }],
        }, {
            'raw': '174;21;TEMP_UNIT;1;7;high;unsigned char;0;1;;1;1;1;0;999999;1;0',
            'label_id': 999999,
            'label': 'TEMP',
            'label_source': 'parameter_fallback',
            'unit_id': 7,
            'unit': '°C',
            'tabs': [],
        }])
        self.assertEqual(row_b['results'], [])

    def test_absent_metadata_tables_leave_backwards_compatible_read_row(self):
        self.table('ecu', 'PARAMS', ['7;22,64,10;RPM;3;0;105000;1;0'])
        row = compile_catalog(self.root, self.texts, self.units)['ecu'][0]
        self.assertEqual(row['id'], '7')
        self.assertEqual(row['did'], 0x6410)
        self.assertEqual(row['raw'], '7;22,64,10;RPM;3;0;105000;1;0')
        self.assertEqual(row['results'], [])


if __name__ == '__main__':
    unittest.main()
