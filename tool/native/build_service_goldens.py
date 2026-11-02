"""Build independent static service-dispatch vectors from retained source rows."""
import hashlib
import json
import re
from datetime import datetime
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
RESEARCH = ROOT / 'assets/research'
NATIVE = RESEARCH / 'recovered-native'
TABLES = NATIVE / 'runtime-tables'
DISPATCH = ROOT / 'docs/parity/P0-05-service-dispatch-evidence.md'
SERVICE_EVIDENCE = RESEARCH / 'service-reset-recovery.md'
ROUTING = NATIVE / 'handler-routing.json'
GROUPS = NATIVE / 'ecu-groups.json'
OUTPUT = ROOT / 'test/fixtures/service_dispatch_goldens.json'

SOURCES = [
    DISPATCH,
    SERVICE_EVIDENCE,
    RESEARCH / 'service-C-sl0.txt',
    RESEARCH / 'service-Lsl0.txt',
    RESEARCH / 'service-Lsy3.txt',
    RESEARCH / 'service-Lry3.txt',
    RESEARCH / 'service-Lxy3.txt',
    RESEARCH / 'service-Lq8.txt',
    RESEARCH / 'service-Llq1.txt',
    GROUPS,
    ROUTING,
]


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def load(path):
    return json.loads(path.read_text())


def source_ref(path):
    return {'path': str(path.relative_to(ROOT)), 'sha256': digest(path)}


def parse_service_routes(text):
    routes = []
    for line in text.splitlines():
        if not (line.startswith('| `G_MRKOMB` |') or line.startswith('| `G_MRSLZ` |')):
            continue
        columns = [value.strip() for value in line.strip().strip('|').split('|')]
        group = columns[0].strip('`')
        selector = re.search(r'`([^`]+)`\s*/\s*(\d+)', columns[1])
        if selector is None:
            raise ValueError(f'Unparsed controller selector: {line}')
        response_routes = re.findall(r'`(\d+)`\s*→\s*`([^`]+)`', columns[2])
        if not response_routes:
            raise ValueError(f'Unparsed response selector list: {line}')
        for response_id, ecu_key in response_routes:
            routes.append({
                'group': group,
                'factory_selector': selector.group(1),
                'address': int(selector.group(2)),
                'response_id': int(response_id),
                'ecu_key': ecu_key,
                'function_category': columns[3].strip('`'),
            })
    return routes


def year_bytes(year):
    return [(year >> 8) & 0xff, year & 0xff]


def build_actions():
    vehicle_time = datetime(2026, 11, 2, 12, 34, 56)
    next_service_date = datetime(2027, 6, 15)
    mileage = 54321
    clock = [vehicle_time.hour, vehicle_time.minute, vehicle_time.second,
             vehicle_time.day, vehicle_time.month, *year_bytes(vehicle_time.year)]
    date = [next_service_date.day, next_service_date.month,
            *year_bytes(next_service_date.year)]
    mileage_bytes = [(mileage >> 8) & 0xff, mileage & 0xff]
    writes = {
        'vehicleDateTime': [0x2e, 0xe1, 0x2b, *clock],
        'nextServiceDate': [0x2e, 0xe1, 0x2c, *date],
        'nextServiceMileage': [0x2e, 0xe1, 0x2d, *mileage_bytes],
    }
    actions = [
        {'event_id': 0, 'event_name': 'SI_ALL', 'action': 'all',
         'write_names': ['vehicleDateTime', 'nextServiceDate', 'nextServiceMileage']},
        {'event_id': 1, 'event_name': 'SI_DATE', 'action': 'nextServiceDate',
         'write_names': ['nextServiceDate']},
        {'event_id': 2, 'event_name': 'SI_MILEAGE', 'action': 'nextServiceMileage',
         'write_names': ['nextServiceMileage']},
        {'event_id': 3, 'event_name': 'SI_DATE_CAR', 'action': 'vehicleDateTime',
         'write_names': ['vehicleDateTime']},
    ]
    for action in actions:
        action['writes'] = []
        for name in action['write_names']:
            request = writes[name]
            action['writes'].append({
                'name': name,
                'request': request,
                'did': (request[1] << 8) | request[2],
                'positive_ack_reply': [0x6e, request[1], request[2]],
                # Synthetic UDS NRC input used to check this application's
                # stricter failure handling; original sl0.C discards replies.
                'synthetic_negative_reply': [0x7f, 0x2e, 0x22],
            })
        action['input'] = {
            'vehicle_date_time_local': '2026-11-02T12:34:56',
            'next_service_date_local': '2027-06-15T00:00:00',
            'next_service_mileage_km': mileage,
        }
        action['start_requests'] = []
        action['pre_read_requests'] = []
        action['source_ack_semantics'] = (
            'sl0.C reads each transfer result but discards it; positive ACK rows are synthetic inputs for the strict local UDS contract.'
        )

    post_reads = [
        {'request': [0x22, 0xe1, 0x19], 'reply': [0x62, 0xe1, 0x19, 0, 0, 0, 42]},
        {'request': [0x22, 0xe1, 0x2b], 'reply': [0x62, 0xe1, 0x2b, *clock]},
        {'request': [0x22, 0xe1, 0x2d], 'reply': [0x62, 0xe1, 0x2d, *mileage_bytes]},
        {'request': [0x22, 0xe1, 0x2c], 'reply': [0x62, 0xe1, 0x2c, *date]},
    ]
    for action in actions:
        action['post_readback'] = post_reads
        action['synthetic_readback_negative_reply'] = [0x7f, 0x22, 0x22]
    return actions


def build():
    dispatch_text = DISPATCH.read_text()
    routes = parse_service_routes(dispatch_text)
    assert len(routes) == 12
    assert {route['function_category'] for route in routes} == {'CF_SERVICE'}
    assert len({route['ecu_key'] for route in routes}) == 12

    group_rows = load(GROUPS)['records']
    groups_by_module = {row['modulegroup']: row for row in group_rows}
    route_rows = []
    for route in routes:
        group = groups_by_module[route['group']]
        assert int(group['defaultaddress']) == route['address']
        function_path = TABLES / route['ecu_key'] / 'FUNCTIONS.json'
        function_table = load(function_path)
        raw_functions = [row for row in function_table['rows']
                         if row.split(';')[0] == '12']
        assert len(raw_functions) == 1
        function_fields = raw_functions[0].split(';')
        assert int(function_fields[0]) == 12 and int(function_fields[1]) == 1
        route_rows.append({
            **route,
            'ecu_group_id': group['id'],
            'database_defaultprotocolid_raw': group['defaultprotocolid'],
            'ecu_group_raw_row': group,
            'functions_raw_row': raw_functions[0],
            'functions_file_sha256': digest(function_path),
            'functions_capture_sha256': function_table['sha256'],
            'handler_family': 'UDS sl0.C inherited by a source-selected sl0 descendant',
            'concrete_subclass_per_response_id': 'not independently retained; no subclass is inferred',
            'source_refs': [source_ref(GROUPS), source_ref(function_path),
                            source_ref(DISPATCH)],
        })

    routing = load(ROUTING)
    routing_candidates = {row['ecu_key'] for row in routing['candidate_key_inventory']}
    assert {route['ecu_key'] for route in route_rows} <= routing_candidates

    service_function_candidates = []
    service_function_keys = sorted({
        edge.get('from', {}).get('value')
        for edge in routing['handler_edges']
        if edge.get('to', {}).get('value') == 'CF_SERVICE_FUNCTIONS'
        and edge.get('rows_retained_by_loader', 0) > 0
    })
    for key in service_function_keys:
        path = TABLES / key / 'FUNCTIONS.json'
        table = load(path)
        service_function_candidates.append({
            'ecu_key': key,
            'functions_raw_row': next(row for row in table['rows']
                                      if row.split(';')[0] == '11'),
            'functions_file_sha256': digest(path),
            'status': 'FUNCTIONS_UI_FLAG_ONLY; handler action scope remains source review',
        })
    assert len(service_function_candidates) == 9

    route_source = routing['source']
    return {
        'source': {
            'artifact': 'MotoScan 1.110 APK / classes.dex / arm64 libmotoscan-helper.so',
            'apk_sha256': route_source['apk_sha256'],
            'classes_dex_sha256': route_source['classes_dex_sha256'],
            'native_library_sha256': route_source['library_sha256'],
            'classification': 'STATIC_GOLDEN chosen synthetic values; no original app or ECU execution is claimed',
            'input_values': {
                'vehicle_date_time_local': '2026-11-02T12:34:56',
                'next_service_date_local': '2027-06-15T00:00:00',
                'next_service_mileage_km': 54321,
            },
            'source_files': {str(path.relative_to(ROOT)): digest(path) for path in SOURCES},
            'dex_offsets': {
                'FUNCTIONS category parser/switch': 'jl0 @ 0x2198b4; switch 0x219902/data 0x2199bc',
                'modulegroup factory': 'fx.I @ 0x1b59d8; cr.c @ 0x175288; ak1.c @ 0x297c4c',
                'event handoff': 'sy3.g @ 0x401e58; ry3.doInBackground @ 0x40197c-0x4019c6',
                'sl0 service handler': 'sl0.C @ 0x21fe78',
                'writes': {'E12B': '0x21ff6a-0x21ffa2',
                           'E12C': '0x22003a-0x220072',
                           'E12D': '0x2200b4-0x2200f0'},
                'readback': 'q8 @ 0x129e5c-0x129e88; sl0.r source offsets documented in service-reset-recovery.md',
            },
            'write_timeout_ms': 2000,
            'settle_after_each_write_ms': 1500,
            'original_handler_response_handling': 'It reads transfer result objects but discards response bytes/status; UI reports success then starts q8 readback.',
            'synthetic_ack_scope': 'Fixture ACK/NRC/readback replies exercise the local strict link contract; they are not original ECU captures.',
        },
        'routes': route_rows,
        'actions': build_actions(),
        'unresolved_legacy_kwp': {
            'status': 'UNRESOLVED_no_ECU_key_FUNCTIONS_join_or_complete_action_body',
            'factory_selector': 'D_MRKOMB → cr(6), address 96',
            'response_labels': [
                {'response_id': 26640, 'handler': 'qr.C', 'legacy_label': 'MRKOMB18'},
                {'response_id': 24832, 'handler': 'rr.C', 'legacy_label': 'MRKOMBI'},
                {'response_id': 24848, 'handler': 'rr.C', 'legacy_label': 'MRKOMB46'},
            ],
            'CF_SERVICE_FUNCTIONS_rows_without_KWP_join': service_function_candidates,
            'reason': 'No source-backed edge maps these legacy response labels to the ECU-key-scoped CF_SERVICE_FUNCTIONS rows. KWP frames/start/readback are not emitted as executable goldens until that join and method behavior are pinned.',
            'source': source_ref(DISPATCH),
        },
    }


def main():
    OUTPUT.write_text(json.dumps(build(), ensure_ascii=False, separators=(',', ':')) + '\n')
    print(f'Wrote {len(load(OUTPUT)["routes"])} UDS routes and four source-derived event families')


if __name__ == '__main__':
    main()
