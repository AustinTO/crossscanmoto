import 'dart:async';
import 'dart:collection';

import 'package:crossscanmoto/diagnostics/kwp_client.dart';
import 'package:crossscanmoto/diagnostics/uds_client.dart';

/// Exact-request replay fake shared by UDS and KWP focused tests.
class ScriptedRequestExchange {
  const ScriptedRequestExchange(this.request, this.reply);

  final List<int> request;
  final List<int> reply;
}

class ScriptedUdsRequestLink implements UdsRequestLink {
  ScriptedUdsRequestLink(Iterable<ScriptedRequestExchange> exchanges)
    : _exchanges = Queue.of(exchanges);

  final Queue<ScriptedRequestExchange> _exchanges;
  final requests = <List<int>>[];
  Completer<List<int>>? heldReply;

  @override
  Future<List<int>> request(List<int> payload, {Duration? timeout}) async {
    requests.add(List.unmodifiable(payload));
    if (_exchanges.isEmpty) {
      throw StateError('Unexpected UDS request: $payload');
    }
    final exchange = _exchanges.first;
    if (!_sameBytes(payload, exchange.request)) {
      throw StateError(
        'Expected UDS request ${exchange.request}, got $payload',
      );
    }
    _exchanges.removeFirst();
    final held = heldReply;
    if (held != null) return held.future;
    return List.unmodifiable(exchange.reply);
  }

  void verifyComplete() {
    if (_exchanges.isNotEmpty) {
      throw StateError('${_exchanges.length} UDS replay requests remain');
    }
  }
}

class ScriptedKwpRequestLink implements KwpRequestLink {
  ScriptedKwpRequestLink(
    Iterable<ScriptedRequestExchange> exchanges, {
    required Iterable<bool> startCommunicationReplies,
  }) : _exchanges = Queue.of(exchanges),
       _startCommunicationReplies = Queue.of(startCommunicationReplies);

  final Queue<ScriptedRequestExchange> _exchanges;
  final Queue<bool> _startCommunicationReplies;
  final requests = <List<int>>[];
  Completer<List<int>>? heldReply;

  @override
  Future<List<int>> request(List<int> payload, {Duration? timeout}) async {
    requests.add(List.unmodifiable(payload));
    if (_exchanges.isEmpty) {
      throw StateError('Unexpected KWP request: $payload');
    }
    final exchange = _exchanges.first;
    if (!_sameBytes(payload, exchange.request)) {
      throw StateError(
        'Expected KWP request ${exchange.request}, got $payload',
      );
    }
    _exchanges.removeFirst();
    final held = heldReply;
    if (held != null) return held.future;
    return List.unmodifiable(exchange.reply);
  }

  @override
  Future<bool> startCommunication() async {
    if (_startCommunicationReplies.isEmpty) {
      throw StateError('No scripted KWP startCommunication result remains');
    }
    return _startCommunicationReplies.removeFirst();
  }

  void verifyComplete() {
    if (_exchanges.isNotEmpty) {
      throw StateError('${_exchanges.length} KWP replay requests remain');
    }
    if (_startCommunicationReplies.isNotEmpty) {
      throw StateError(
        '${_startCommunicationReplies.length} KWP start results remain',
      );
    }
  }
}

bool _sameBytes(List<int> left, List<int> right) {
  if (left.length != right.length) return false;
  for (var index = 0; index < left.length; index++) {
    if (left[index] != right[index]) return false;
  }
  return true;
}
