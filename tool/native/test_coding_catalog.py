"""Unit tests for the recovered native ECU coding catalog."""
import json
import unittest
from pathlib import Path


class CodingCatalogTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.root = Path(__file__).resolve().parents[2]
        cls.catalog_path = cls.root / 'assets/data/recovered_coding_definitions.json'
        with open(cls.catalog_path, 'r', encoding='utf-8') as f:
            cls.catalog = json.load(f)

    def test_catalog_overall_counts(self):
        self.assertGreaterEqual(self.catalog['total_variants'], 45)
        self.assertGreaterEqual(self.catalog['total_parameters'], 3000)
        self.assertGreaterEqual(self.catalog['total_options'], 8000)
        self.assertEqual(len(self.catalog['variants']), self.catalog['total_variants'])

    def test_kmbi_k25_c04_structure(self):
        self.assertIn('KMBI_K25_C04', self.catalog['variants'])
        variant = self.catalog['variants']['KMBI_K25_C04']
        self.assertEqual(variant['ecu_family'], 'KMBI_K25')
        self.assertEqual(variant['coding_index'], '04')
        self.assertEqual(variant['header'], 'KMBI_K25.C04')
        self.assertEqual(variant['block_count'], 4)

        # Check block Country_Code
        block_names = [b['name'] for b in variant['blocks']]
        self.assertIn('Country_Code', block_names)
        self.assertIn('Equipment', block_names)
        self.assertIn('Display', block_names)
        self.assertIn('Service_Anzeige', block_names)

        country = next(b for b in variant['blocks'] if b['name'] == 'Country_Code')
        self.assertEqual(country['did'], 0x3005)
        self.assertEqual(country['did_hex'], '0x3005')

        # Check CLOCK_MODE param
        clock = next(p for p in country['parameters'] if p['name'] == 'CLOCK_MODE')
        self.assertEqual(clock['offset'], 1)
        self.assertEqual(clock['bitmask'], 0x01)
        clock_opts = {o['name']: o['raw_hex'] for o in clock['options']}
        self.assertIn('24h', clock_opts)
        self.assertIn('12h', clock_opts)
        self.assertEqual(clock_opts['24h'], '01')
        self.assertEqual(clock_opts['12h'], '00')

        # Check ODO_UNIT param
        odo = next(p for p in country['parameters'] if p['name'] == 'ODO_UNIT')
        self.assertEqual(odo['offset'], 1)
        self.assertEqual(odo['bitmask'], 0x04)
        odo_opts = {o['name']: o['raw_hex'] for o in odo['options']}
        self.assertEqual(odo_opts['km'], '00')
        self.assertEqual(odo_opts['mls'], '01')

    def test_zfe_c08_structure(self):
        self.assertIn('ZFE_C08', self.catalog['variants'])
        variant = self.catalog['variants']['ZFE_C08']
        self.assertEqual(variant['ecu_family'], 'ZFE')
        self.assertEqual(variant['coding_index'], '08')

        all_params = [
            p['name']
            for b in variant['blocks']
            for p in b['parameters']
        ]
        self.assertIn('LED_KL54_OUTPUT', all_params)
        self.assertIn('LED_KL58R_OUTPUT', all_params)
        self.assertIn('TIME_INDIC_LIMIT', all_params)
        self.assertIn('DISTANCE_INDIC_LIMIT', all_params)

    def test_bmsk_c00_structure(self):
        self.assertIn('BMSK_C00', self.catalog['variants'])
        variant = self.catalog['variants']['BMSK_C00']
        self.assertEqual(variant['ecu_family'], 'BMSK')
        self.assertEqual(variant['coding_index'], '00')
        self.assertGreaterEqual(variant['parameter_count'], 6)

    def test_block_dids_and_offsets_are_valid(self):
        for key, variant in self.catalog['variants'].items():
            for block in variant['blocks']:
                self.assertGreater(block['did'], 0)
                self.assertLessEqual(block['did'], 0xFFFF)
                self.assertGreaterEqual(block['offset'], 0)
                self.assertGreaterEqual(block['length'], 0)
                for param in block['parameters']:
                    self.assertGreater(param['did'], 0)
                    self.assertGreaterEqual(param['offset'], 0)
                    self.assertGreater(param['bitmask'], 0)
                    self.assertLessEqual(param['bitmask'], 0xFFFFFFFF)


if __name__ == '__main__':
    unittest.main()
