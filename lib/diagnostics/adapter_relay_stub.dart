import 'adapter_relay_types.dart';
import 'elm_session.dart';

class AdapterRelayServer {
  static Future<AdapterRelayServer> start({
    required bool diagnosticSessionConnected,
    required Future<AdapterTransport> Function() connectBluetooth,
    int port = 0,
  }) =>
      Future.error(
          UnsupportedError('Adapter relay hosting requires a native app.'));

  AdapterRelayInfo get info =>
      throw UnsupportedError('Adapter relay is unavailable.');
  AdapterRelayState get state => AdapterRelayState.stopped;
  Stream<AdapterRelayState> get stateChanges => const Stream.empty();
  bool get isRunning => false;

  Future<void> stop() async {}
}
