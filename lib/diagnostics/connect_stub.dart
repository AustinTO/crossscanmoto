import 'elm_session.dart';
Future<AdapterTransport> connectAdapter(String host, int port) =>
    Future.error(UnsupportedError('Direct TCP adapters require a native app.'));
