"""Build compact source-derived service category/controller route fixtures."""
import hashlib
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
NATIVE = ROOT / 'assets/research/recovered-native'
TABLES = NATIVE / 'runtime-tables'
DEX_HASH = '869025551e5339811c300f2ae5ec92563c7e6b228d9498b8e835e2ac79283832'
APK_HASH = 'bfc07ce264a0c35df9d63558f4fa64c4bd3dd845903d3e0417532250ea0e7e58'
LIB_HASH = 'bab0c173bb33c37262d07bbbbdc2c91213275d2a68e941d1b39fc3affd34fc71'
OUT = ROOT / 'docs/parity/fixtures/P0-05-service-controller-routes.json'

# Exact identifiers in fx.I(String) and cr.c(int)/ak1.c(int), recovered from
# DEX at the offsets stored below. Selector values are cr/ak1 constructor args.
FACTORIES = {
    'G_MRKOMB': {'factory_class': 'cr', 'selector': 23, 'address': 96, 'fx_offset': '0x1b5eca', 'protocol_id': '8'},
    'G_MRSLZ': {'factory_class': 'ak1', 'selector': 0, 'address': 64, 'fx_offset': '0x1b5b18', 'protocol_id': '8'},
    'G_MRABS': {'factory_class': 'cr', 'selector': 11, 'address': 41, 'fx_offset': '0x1b5df2', 'protocol_id': '8'},
    'G_MRESA': {'factory_class': 'cr', 'selector': 20, 'address': 56, 'fx_offset': '0x1b5c64', 'protocol_id': '8'},
    'G_MRFSA': {'factory_class': 'cr', 'selector': 21, 'address': 14, 'fx_offset': '0x1b5c3e', 'protocol_id': '8'},
    'G_MRRDC': {'factory_class': 'cr', 'selector': 28, 'address': 32, 'fx_offset': '0x1b5b6c', 'protocol_id': '8'},
    'G_MRSAF': {'factory_class': 'cr', 'selector': 29, 'address': 57, 'fx_offset': '0x1b5b42', 'protocol_id': '8'},
    'D_MRKOMB': {'factory_class': 'cr', 'selector': 6, 'address': 96, 'fx_offset': '0x1b5f1e', 'protocol_id': '3'},
}

# The values are exact response identifiers passed to cr.c/ak1.c. Handler class
# and ECU key are recovered from the constructor and Lel0.e assignments.
UDS_SERVICE_HANDLERS = {
    ('G_MRKOMB', 1017856): ('i15', 'cuX_KOMBI'),
    ('G_MRKOMB', 1017936): ('i15', 'cuX_KOMB50'),
    ('G_MRKOMB', 1017952): ('f15', 'cuX_KOMB53'),
    ('G_MRKOMB', 1017984): ('f15', 'cuX_KOMB17'),
    ('G_MRKOMB', 1018000): ('f15', 'cuX_KOMB46'),
    ('G_MRKOMB', 1019968): ('i15', 'cuX_KOMB18'),
    ('G_MRKOMB', 1020000): ('i15', 'cuX_KOMB03'),
    ('G_MRKOMB', 1020016): ('f15', 'cuX_KOMBLO'),
    ('G_MRKOMB', 1020032): ('f15', 'cuX_KOMBHI'),
    ('G_MRKOMB', 1020034): ('i15', 'cuX_KOMBB2'),
    ('G_MRKOMB', 1020037): ('i15', 'cuX_KOMB_A'),
    ('G_MRSLZ', 1020064): ('f15', 'cuX_CCP'),
}
SERVICE_FUNCTION_HANDLERS = {
    ('G_MRABS', 1016576): ('d15', 'cuX_ABS'),
    ('G_MRABS', 1016608): ('f15', 'cuX_ABS1K'),
    ('G_MRABS', 1016656): ('e15', 'cuX_ABSVI'),
    ('G_MRABS', 1016704): ('c15', 'cuX_ABS9M'),
    ('G_MRESA', 1016832): ('g15', 'cuX_ESA'),
    ('G_MRFSA', 1015808): ('h15', 'cuX_FSA'),
    ('G_MRFSA', 1015824): ('f15', 'cuX_FSM'),
    ('G_MRRDC', 1016064): ('j15', 'cuX_RDC'),
    ('G_MRSAF', 1017088): ('k15', 'cuX_SAF'),
    ('G_MRSLZ', 1017344): ('i15', 'cuX_SLZ'),
    ('G_MRSLZ', 1017424): ('l15', 'cuX_SLZ03'),
    ('G_MRSLZ', 1017440): ('m15', 'cuX_SLZ_4'),
    ('G_MRSLZ', 1018880): ('i15', 'cuX_EWS4'),
}
LEGACY_KWP_HANDLERS = {
    24832: ('rr', 1, 'MRKOMBI'),
    24848: ('rr', 0, 'MRKOMB46'),
    24864: ('jr', 8, 'MRKMB461'),
    26624: ('jr', 11, 'MRKOMB71'),
    26640: ('qr', None, 'MRKOMB18'),
    26656: ('jr', 7, 'MRKMB181'),
    27648: ('jr', 10, 'MRKOMB2D'),
}


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main():
    groups_data = json.loads((NATIVE / 'ecu-groups.json').read_text(encoding='utf-8'))
    groups = {row['modulegroup']: row for row in groups_data['records']}
    category_for_key = {}
    for table in sorted(TABLES.glob('*/FUNCTIONS.json')):
        payload = json.loads(table.read_text(encoding='utf-8'))
        for raw in payload['rows']:
            fields = raw.split(';')
            if len(fields) < 2:
                continue
            try:
                category_id, enabled = int(fields[0]), int(fields[1]) == 1
            except ValueError:
                continue
            if enabled and category_id in (11, 12):
                category_for_key.setdefault(table.parent.name, []).append({'raw': raw, 'category_id': category_id})

    routes = []
    for category_id, mapping, type_label, category_name, menu, menu_method in [
        (12, UDS_SERVICE_HANDLERS, 'CF_SERVICE', 'CF_SERVICE', 's40.onItemClick', 'Lel0.M'),
        (11, SERVICE_FUNCTION_HANDLERS, 'CF_SERVICE_FUNCTIONS', 'CF_SERVICE_FUNCTIONS', 's40.onItemClick', 'Lel0.L'),
    ]:
        for (group_name, response_id), (handler_class, ecu_key) in mapping.items():
            group = groups.get(group_name)
            routes.append({
                'category_token0_id': category_id,
                'category': type_label,
                'category_menu_method': menu_method,
                'menu_dispatch_dex_offset': '0x1d6578; case target 0x1d661c for ordinal8 or 0x1d6586 for ordinal13',
                'modulegroup': group_name,
                'group_source_row': group,
                'group_protocol_id_raw': group.get('defaultprotocolid') if group else None,
                'group_defaultaddress_raw': group.get('defaultaddress') if group else None,
                'fx_factory': FACTORIES.get(group_name),
                'response_id': response_id,
                'controller_handler_class': handler_class,
                'controller_handler_key': ecu_key,
                'controller_handler_superclass': 'sl0',
                'inherits_service_write_C': True,
                'function_rows_for_key': category_for_key.get(ecu_key, []),
                'source_dex': {
                    'group_factory_method': 'fx.I(String) @ 0x1b59d8',
                    'response_identifier_selector': 'cr.c(int) @ 0x175288' if group_name != 'G_MRSLZ' else 'ak1.c(int) @ 0x297c4c',
                    'handler_construction': 'cr.c/ak1.c sets Lel0.e to the exact key above; the class directly extends sl0.',
                },
                'limitations': ['Category presence is source-backed; `Lel0.M` has an `el0.s` view gate; exact service-page reachability and per-action replay are documented separately.'],
            })

    legacy = []
    for response_id, (handler_class, selector, controller_key) in LEGACY_KWP_HANDLERS.items():
        legacy.append({
            'modulegroup': 'D_MRKOMB',
            'group_source_row': groups.get('D_MRKOMB'),
            'group_factory': FACTORIES['D_MRKOMB'],
            'response_id': response_id,
            'controller_handler_class': handler_class,
            'constructor_selector': selector,
            'controller_handler_key': controller_key,
            'protocol_evidence': 'Handler implementation is KWP-style; qr.C/rr.C use 0x3B templates. Group defaultprotocolid remains raw ID 3.',
            'functions_row': category_for_key.get(controller_key, []),
            'source_dex': {'group_factory_method': 'fx.I(String) @ 0x1b59d8', 'response_selector': 'cr.c(int) @ 0x175288'},
            'limitations': ['No direct FUNCTIONS row/key join for the legacy MRKOMB* labels is present in the retained catalog. jr routes require separate handler support checks.'],
        })

    payload = {
        'source': {
            'apk_sha256': 'bfc07ce264a0c35df9d63558f4fa64c4bd3dd845903d3e0417532250ea0e7e58',
            'dex_sha256': '869025551e5339811c300f2ae5ec92563c7e6b228d9498b8e835e2ac79283832',
            'functions_tables_sha256_by_key': {
                table.parent.name: json.loads(table.read_text(encoding='utf-8')).get('sha256')
                for table in sorted(TABLES.glob('*/FUNCTIONS.json'))
                if table.parent.name in category_for_key
            },
            'dex_excerpts': 'docs/parity/fixtures/P0-05-service-dispatch-excerpts.txt',
        },
        'category_routes': routes,
        'legacy_kwp_routes': legacy,
        'ui_dispatch': {
            'CF_SERVICE': {'token0_id': 12, 'kl0_ordinal': 8, 'target': 'Lel0.M', 'dex_offsets': ['s40.onItemClick 0x1d661c', 'sl0.M 0x2203fc', 'pl0.M 0x21b7ac']},
            'CF_SERVICE_FUNCTIONS': {'token0_id': 11, 'kl0_ordinal': 13, 'target': 'Lel0.L', 'dex_offsets': ['s40.onItemClick 0x1d6586', 'sl0.L 0x2203e0']},
            'CF_ADAPTIONS': {'token0_id': 8, 'kl0_ordinal': 11, 'target': 'Lel0.E', 'dex_offsets': ['s40.onItemClick 0x1d65c2', 'sl0.E 0x2202e8']},
            'service_reset_action': {'fragment': 'sy3', 'handler_call': 'Lel0.C(dl0,int,Date,Date)', 'dex_offsets': ['sy3.g 0x401e58', 'ry3.doInBackground 0x40197c / invoke C 0x4019c6']},
            'service_page_gate': {'condition': 'sl0.M/pl0.M return generic Gv2 if Lel0.s == true; return sy3 if false.', 'dex_offsets': ['Lel0.<init> initializes s=true at 0x22a262', 'sl0.M 0x22040c-0x220428', 'pl0.M 0x21b7bc-0x21b7d8'], 'boundary': 'No additional DEX field writes to Lel0.s were found; do not infer runtime mutation or global page reachability from this search alone.'},
        },
    }
    OUT.write_text(json.dumps(payload, ensure_ascii=False, indent=2) + '\n')
    print('Wrote', OUT, len(routes), 'category routes and', len(legacy), 'legacy paths')


if __name__ == '__main__':
    main()
