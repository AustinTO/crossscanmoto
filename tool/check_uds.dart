import '../lib/diagnostics/uds_response.dart';
void check(bool value) { if (!value) throw StateError('UDS check failed'); }
void main() {
 final response=UdsResponse.decode([0x62,0xF1,0x90,0x41],requestService:0x22) as UdsPositiveResponse;
 check(response.service==0x62 && response.data.length==3);
 final pending=UdsResponse.decode([0x7F,0x22,0x78],requestService:0x22) as UdsNegativeResponse;
 check(pending.isPending);
 for (final bytes in <List<int>>[[],[0x7F],[0x7F,0x19,0x78],[0x63],[256]]) {
   try { UdsResponse.decode(bytes,requestService:0x22); throw StateError('Invalid response accepted'); } on FormatException { }
 }
 // ignore: avoid_print
 print('PASS: UDS positive responses, response pending, malformed and mismatched rejection');
}
