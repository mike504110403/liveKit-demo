import 'dart:convert';
import 'dart:async';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../models/chat_message.dart';
import '../config/app_config.dart';

class WebSocketService {
  WebSocketChannel? _channel;
  final _messageController = StreamController<ChatMessage>.broadcast();
  final _roomClosedController = StreamController<String>.broadcast();
  final _streamStoppedController = StreamController<String>.broadcast();
  final _streamStartedController = StreamController<String>.broadcast();

  Stream<ChatMessage> get messages => _messageController.stream;
  Stream<String> get onRoomClosed => _roomClosedController.stream;
  Stream<String> get onStreamStopped => _streamStoppedController.stream;
  Stream<String> get onStreamStarted => _streamStartedController.stream;
  static String get wsUrl => AppConfig.wsBaseUrl;

  Future<void> connect(String roomId, String token) async {
    _channel = WebSocketChannel.connect(
      Uri.parse('$wsUrl/chat/$roomId?token=$token'),
    );

    _channel!.stream.listen((data) {
      final json = jsonDecode(data);

      // 檢查是否為房間關閉事件
      if (json['type'] == 'room_closed') {
        print('🚪 [WebSocket] 收到房間關閉通知: ${json['message']}');
        _roomClosedController.add(json['message']);
        return;
      }

      // 檢查是否為停止直播事件
      if (json['type'] == 'stream_stopped') {
        print('⏹️  [WebSocket] 收到停止直播通知: ${json['message']}');
        _streamStoppedController.add(json['message']);
        return;
      }

      // 檢查是否為開始直播事件
      if (json['type'] == 'stream_started') {
        print('▶️  [WebSocket] 收到開始直播通知: ${json['message']}');
        _streamStartedController.add(json['message']);
        return;
      }

      // 正常聊天消息
      final message = ChatMessage.fromJson(json);
      _messageController.add(message);
    });
  }

  Future<void> sendMessage(String message) async {
    if (_channel != null) {
      _channel!.sink.add(jsonEncode({'message': message}));
    }
  }

  void disconnect() {
    _channel?.sink.close();
    _channel = null;
  }

  void dispose() {
    _messageController.close();
    _roomClosedController.close();
    _streamStoppedController.close();
    _streamStartedController.close();
  }
}
