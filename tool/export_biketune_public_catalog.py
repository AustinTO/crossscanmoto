#!/usr/bin/env python3
"""Deterministic exporter for safe, non-sensitive Biketune public catalog metadata.

Excludes proprietary cryptography keys (bootloader_keys, coding_keys) and outputs
reproducible, sorted JSON metadata with source provenance manifest.
"""

import argparse
import hashlib
import json
from pathlib import Path
import sqlite3
from urllib.parse import quote

EXCLUDED_TABLES = {
    'bootloader_keys': 'Contains sensitive bootloader authorization keys',
    'coding_keys': 'Contains proprietary coding unlock keys',
    'coding_functions': 'CAFD bit-level coding definitions (separate CAFD domain)',
    'coding_labels': 'Raw CAFD translation strings',
    'coding_options': 'Raw CAFD option tables',
    'coding_preset_items': 'Internal UI preset items',
    'coding_preset_options': 'Internal UI preset options',
    'coding_presets': 'Internal UI preset headers',
    'coding_retrofit_items': 'Raw retrofit mapping items',
    'coding_retrofit_sets': 'Raw retrofit mapping sets',
    'coding_retrofits': 'Raw retrofit headers',
    'coding_groups': 'Internal coding groups',
    'dtc_events': 'Raw fault event strings',
    'dtc_labels': 'Raw fault label strings',
    'ecu_aliases': 'Internal alias records',
    'ecu_jobs': 'EDIABAS job strings',
    'ecu_routines': 'EDIABAS routine strings',
    'equipment_config': 'Vehicle equipment configurations',
    'guide_codes': 'Troubleshooting guide codes',
    'guides': 'Troubleshooting text guides',
    'live_param_labels': 'Raw live telemetry label translations',
    'live_params': 'Raw live telemetry parameter mappings',
    'mr_coding_aliases': 'Internal coding aliases',
    'mr_coding_params': 'Internal coding parameter mappings',
    'mr_coding_records': 'Internal coding records',
    'mr_coding_units': 'Internal coding units',
    'ncd_pages': 'Internal NCD binary pages',
    'platform_ecus': 'Internal platform ECU bridge',
    'sa_codes': 'BMW Sonderausstattung equipment option codes',
    'schema_meta': 'Internal SQLite metadata',
}

def export_catalog(db_path: Path, out_path: Path):
    db_path = db_path.resolve()
    if not db_path.is_file():
        raise FileNotFoundError(f'Database file not found: {db_path}')

    src_bytes = db_path.read_bytes()
    src_sha256 = hashlib.sha256(src_bytes).hexdigest()

    conn = sqlite3.connect(f'file:{quote(str(db_path), safe="/")}?mode=ro', uri=True)
    try:
        conn.execute('PRAGMA query_only=ON')
        integrity = conn.execute('PRAGMA integrity_check').fetchone()[0]
        if integrity != 'ok':
            raise RuntimeError(f'SQLite integrity check failed: {integrity}')

        # 1. Bikes (83)
        bikes = []
        for r in conn.execute(
            'SELECT ebr, series, model_name, year_begin, year_end, series_group, protocol, notes, disabled, platform_id '
            'FROM bikes ORDER BY ebr'
        ):
            bikes.append({
                'ebr': r[0],
                'series': r[1],
                'model_name': r[2],
                'year_begin': r[3],
                'year_end': r[4],
                'series_group': r[5],
                'protocol': r[6],
                'notes': r[7],
                'disabled': bool(r[8]),
                'platform_id': r[9],
            })

        # 2. Bike Market Models (128)
        market_models = []
        for r in conn.execute(
            'SELECT ebr, name, series_letter, ordinal FROM bike_market_models ORDER BY ebr, ordinal, name'
        ):
            market_models.append({
                'ebr': r[0],
                'name': r[1],
                'series_letter': r[2],
                'ordinal': r[3],
            })

        # 3. Bike Variants (258)
        variants = []
        for r in conn.execute(
            'SELECT ebr, variant_code FROM bike_variants ORDER BY ebr, variant_code'
        ):
            variants.append({
                'ebr': r[0],
                'variant_code': r[1],
            })

        # 4. Bike ECUs (778)
        bike_ecus = []
        for r in conn.execute(
            'SELECT ebr, ecu_name, source FROM bike_ecus ORDER BY ebr, ecu_name'
        ):
            bike_ecus.append({
                'ebr': r[0],
                'ecu_name': r[1],
                'source': r[2],
            })

        # 5. ECUs (95)
        ecus = []
        for r in conn.execute(
            'SELECT name, address, description, cafd_root, disabled FROM ecus ORDER BY name'
        ):
            ecus.append({
                'name': r[0],
                'address': r[1],
                'description': r[2],
                'cafd_root': r[3],
                'disabled': bool(r[4]),
            })

        # 6. Service Functions (98)
        service_functions = []
        for r in conn.execute(
            'SELECT id, ecu_name, function_id, category, label, description, disabled, sort FROM service_functions ORDER BY id'
        ):
            service_functions.append({
                'id': r[0],
                'ecu_name': r[1],
                'function_id': r[2],
                'category': r[3],
                'label': r[4],
                'description': r[5],
                'disabled': bool(r[6]),
                'sort': r[7],
            })

        # 7. Service Steps (397)
        service_steps = []
        for r in conn.execute(
            'SELECT id, function_pk, step_order, kind, text, request_pdu, stop_pdu, positive_response, '
            'keepalive_ms, wait_ms, repeat, hold_pdu FROM service_steps ORDER BY id'
        ):
            service_steps.append({
                'id': r[0],
                'function_pk': r[1],
                'step_order': r[2],
                'kind': r[3],
                'text': r[4],
                'request_pdu': r[5],
                'stop_pdu': r[6],
                'positive_response': r[7],
                'keepalive_ms': r[8],
                'wait_ms': r[9],
                'repeat': r[10],
                'hold_pdu': r[11],
            })

        # 8. Actuators (148)
        actuators = []
        for r in conn.execute(
            'SELECT id, ecu_name, actuator_id, label, request_pdu, positive_response, wait_ms, name, description, disabled FROM actuators ORDER BY id'
        ):
            actuators.append({
                'id': r[0],
                'ecu_name': r[1],
                'actuator_id': r[2],
                'label': r[3],
                'request_pdu': r[4],
                'positive_response': r[5],
                'wait_ms': r[6],
                'name': r[7],
                'description': r[8],
                'disabled': bool(r[9]),
            })

        # 9. Adaptations (13)
        adaptations = []
        for r in conn.execute(
            'SELECT id, ecu_name, adaptation_id, kind, read_did, reset_pdu, reset_response, label, description, disabled FROM adaptations ORDER BY id'
        ):
            adaptations.append({
                'id': r[0],
                'ecu_name': r[1],
                'adaptation_id': r[2],
                'kind': r[3],
                'read_did': r[4],
                'reset_pdu': r[5],
                'reset_response': r[6],
                'label': r[7],
                'description': r[8],
                'disabled': bool(r[9]),
            })

        # 10. SWE Versions (526)
        swe_versions = []
        for r in conn.execute(
            'SELECT cafd_root, version, date, notes, chassis FROM swe_versions ORDER BY cafd_root, version'
        ):
            swe_versions.append({
                'cafd_root': r[0],
                'version': r[1],
                'date': r[2],
                'notes': r[3],
                'chassis': r[4],
            })

        # 11. ECU Variants (119)
        ecu_variants = []
        for r in conn.execute(
            'SELECT address, variant_index, index_bytes, sgbd, ecu_group, description, generation, disabled FROM ecu_variants ORDER BY address, variant_index'
        ):
            ecu_variants.append({
                'address': r[0],
                'variant_index': r[1],
                'index_bytes': r[2],
                'sgbd': r[3],
                'ecu_group': r[4],
                'description': r[5],
                'generation': r[6],
                'disabled': bool(r[7]),
            })

        table_counts = {
            'bikes': len(bikes),
            'bike_market_models': len(market_models),
            'bike_variants': len(variants),
            'bike_ecus': len(bike_ecus),
            'ecus': len(ecus),
            'service_functions': len(service_functions),
            'service_steps': len(service_steps),
            'actuators': len(actuators),
            'adaptations': len(adaptations),
            'swe_versions': len(swe_versions),
            'ecu_variants': len(ecu_variants),
        }

        output_doc = {
            'manifest': {
                'source_sha256': src_sha256,
                'source_bytes': len(src_bytes),
                'sqlite_integrity': integrity,
                'source_version': 'Biketune 1.9.1 recovered live library',
                'exported_table_counts': table_counts,
                'excluded_tables': EXCLUDED_TABLES,
            },
            'bikes': bikes,
            'bike_market_models': market_models,
            'bike_variants': variants,
            'bike_ecus': bike_ecus,
            'ecus': ecus,
            'service_functions': service_functions,
            'service_steps': service_steps,
            'actuators': actuators,
            'adaptations': adaptations,
            'swe_versions': swe_versions,
            'ecu_variants': ecu_variants,
        }

        json_bytes = (json.dumps(output_doc, indent=2, sort_keys=True) + '\n').encode('utf-8')
        out_path.parent.mkdir(parents=True, exist_ok=True)
        out_path.write_bytes(json_bytes)
        out_hash = hashlib.sha256(json_bytes).hexdigest()

        print(f'Exported {sum(table_counts.values())} rows across {len(table_counts)} tables.')
        print(f'Output SHA-256: {out_hash} -> {out_path}')
        return out_hash

    finally:
        conn.close()

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--db', default='assets/research/biketune-live/library.decrypted.db')
    parser.add_argument('--out', default='assets/data/bmw_biketune_catalog.json')
    args = parser.parse_args()

    h1 = export_catalog(Path(args.db), Path(args.out))
    # Run twice to verify deterministic SHA-256
    h2 = export_catalog(Path(args.db), Path(args.out))
    if h1 != h2:
        raise RuntimeError(f'Non-deterministic export: {h1} != {h2}')
    print(f'Deterministic verification: PASSED (SHA: {h1})')

if __name__ == '__main__':
    main()
