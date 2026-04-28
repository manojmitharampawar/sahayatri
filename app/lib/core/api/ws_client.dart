import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';

class WSClient {
  WebSocketChannel? _channel;
  final StreamController<Map<String, dynamic>> _messageController =
      StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get messages => _messageController.stream;

  bool get isConnected => _channel != null;

  void connect(int yatraId, String accessToken) {
    final uri = Uri.parse(
        'ws://localhost:8080/api/v1/family/live/$yatraId?token=$accessToken');
    _channel = WebSocketChannel.connect(uri);

    _channel!.stream.listen(
      (data) {
        try {
          final decoded = jsonDecode(data as String) as Map<String, dynamic>;
          _messageController.add(decoded);
        } catch (_) {}
      },
      onError: (error) {
        print('WebSocket error: $error');
        _reconnect(yatraId, accessToken);
      },
      onDone: () {
        print('WebSocket disconnected');
      },
    );
  }

  void _reconnect(int yatraId, String accessToken) {
    Future.delayed(const Duration(seconds: 3), () {
      connect(yatraId, accessToken);
    });
  }

  void disconnect() {
    _channel?.sink.close();
    _channel = null;
  }

  void dispose() {
    disconnect();
    _messageController.close();
  }
}
