import 'elm_session.dart';
import 'tcp_transport.dart';
Future<AdapterTransport> connectAdapter(String host, int port) =>
    TcpAdapterTransport.connect(host, port);
