import 'elm_session.dart';

class RelayAdapterTransport implements AdapterTransport {
  static Future<RelayAdapterTransport> connect(
    String host,
    int port,
    String token,
  ) =>
      Future.error(UnsupportedError('Relay TCP clients require a native app.'));

  @override
  Stream<List<int>> get incoming => const Stream.empty();

  @override
  Future<void> write(List<int> bytes) =>
      Future.error(UnsupportedError('Relay TCP clients require a native app.'));

  @override
  Future<void> close() async {}
}
