import 'dart:io';
import 'elm_session.dart';

class TcpAdapterTransport implements AdapterTransport {
  TcpAdapterTransport._(this._socket);
  final Socket _socket;
  static Future<TcpAdapterTransport> connect(String host, int port,
      {Duration timeout = const Duration(seconds: 5)}) async {
    if (host.trim().isEmpty || port < 1 || port > 65535) {
      throw ArgumentError('Valid adapter host and port required');
    }
    final socket = await Socket.connect(host, port, timeout: timeout);
    socket.setOption(SocketOption.tcpNoDelay, true);
    return TcpAdapterTransport._(socket);
  }

  @override
  Stream<List<int>> get incoming => _socket;
  @override
  Future<void> write(List<int> bytes) async {
    _socket.add(bytes);
    await _socket.flush();
  }

  @override
  Future<void> close() async => _socket.destroy();
}
