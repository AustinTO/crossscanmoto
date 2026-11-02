import 'dart:async';
import 'dart:convert';

import 'package:crossscanmoto/diagnostics/elm_session.dart';

/// One exact ELM command and its prompt-terminated incoming byte fragments.
class ScriptedElmExchange {
  const ScriptedElmExchange(this.command, this.fragments);

  final String command;
  final List<String> fragments;
}

/// Strict replay transport: commands must match the script in order and every
/// script entry must be consumed before [verifyComplete] succeeds.
class ScriptedAdapterTransport implements AdapterTransport {
  ScriptedAdapterTransport(Iterable<ScriptedElmExchange> exchanges)
    : _exchanges = List.of(exchanges);

  final List<ScriptedElmExchange> _exchanges;
  final _incoming = StreamController<List<int>>();
  final writes = <String>[];
  var _next = 0;
  var _closed = false;

  @override
  Stream<List<int>> get incoming => _incoming.stream;

  @override
  Future<void> write(List<int> bytes) async {
    final command = ascii.decode(bytes);
    writes.add(command);
    if (_closed) throw StateError('Scripted transport is closed');
    if (_next >= _exchanges.length) {
      throw StateError('Unexpected adapter command: ${command.trimRight()}');
    }
    final exchange = _exchanges[_next];
    final expected = '${exchange.command}\r';
    if (command != expected) {
      throw StateError('Expected adapter command $expected, got $command');
    }
    _next++;
    for (final fragment in exchange.fragments) {
      _incoming.add(ascii.encode(fragment));
    }
  }

  void verifyComplete() {
    if (_next != _exchanges.length) {
      throw StateError(
        'Replay consumed $_next of ${_exchanges.length} scripted exchanges',
      );
    }
  }

  Future<void> disconnect() async {
    _closed = true;
    await _incoming.close();
  }

  @override
  Future<void> close() async {
    _closed = true;
    await _incoming.close();
  }
}
