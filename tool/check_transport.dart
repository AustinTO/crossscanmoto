import 'dart:async';
import 'dart:convert';
import '../lib/diagnostics/elm_session.dart';
class Transport implements AdapterTransport {
 final controller = StreamController<List<int>>();
 final writes = <String>[];
 @override Stream<List<int>> get incoming => controller.stream;
 @override Future<void> write(List<int> data) async { writes.add(ascii.decode(data)); }
 void receive(String data) => controller.add(ascii.encode(data));
 @override Future<void> close() => controller.close();
}
void check(bool value, String message) { if (!value) throw StateError(message); }
Future<void> main() async {
 final transport=Transport(); final session=ElmSession(transport);
 final first=session.command('ATI'); final second=session.command('ATRV');
 await Future<void>.delayed(Duration.zero);
 check(transport.writes.length==1,'Requests overlap');
 transport.receive('ATI\rELM'); transport.receive('327\r>');
 check((await first).text=='ELM327','Fragmentation/echo failed');
 await Future<void>.delayed(Duration.zero);
 check(transport.writes.length==2,'Queue did not advance');
 transport.receive('12.6V\r>');
 check((await second).text=='12.6V','Voltage response incorrect');
 await session.close();
 final slow=Transport(); final slowSession=ElmSession(slow);
 try { await slowSession.command('ATI',timeout:const Duration(milliseconds:5)); throw StateError('Timeout missing'); } on TimeoutException { }
 slow.receive('LATE\r>');
 try { await slowSession.command('ATRV'); throw ArgumentError('Expected rejection'); } on StateError { }
 check(slow.writes.length==1,'Late response contaminated queue');
 await slowSession.close();
 // ignore: avoid_print
 print('PASS: fragmented frames, echo removal, command serialization, timeout and late response rejection');
}
