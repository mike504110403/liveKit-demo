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
  Timer? _pingTimer;

  Stream<ChatMessage> get messages => _messageController.stream;
  Stream<String> get onRoomClosed => _roomClosedController.stream;
  Stream<String> get onStreamStopped => _streamStoppedController.stream;
  Stream<String> get onStreamStarted => _streamStartedController.stream;
  static String get wsUrl => AppConfig.wsBaseUrl;

  Future<void> connect(String roomId, String token) async {
    final url = '${AppConfig.wsBaseUrl}/chat/$roomId?token=$token';
    print('🔌 [WebSocket] 嘗試連接: $url');
    
    try {
      _channel = WebSocketChannel.connect(
        Uri.parse(url),
      );

      print('✅ [WebSocket] 連接成功');

      // 監聽消息
      _channel!.stream.listen(
        (data) {
          print('📩 [WebSocket] 收到原始數據: $data');
          
          try {
            final json = jsonDecode(data);
            print('📩 [WebSocket] 解析後數據: $json');

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
          } catch (e) {
            print('❌ [WebSocket] 解析消息失敗: $e');
          }
        },
        onError: (error) {
          print('❌ [WebSocket] 連接錯誤: $error');
        },
        onDone: () {
          print('🔌 [WebSocket] 連接已關閉');
          _stopPing();
        },
        cancelOnError: false,
      );

      // 啟動心跳（Web 端響應 Ping）
      _startPing();
      
    } catch (e) {
      print('❌ [WebSocket] 連接失敗: $e');
      rethrow;
    }
  }

  void _startPing() {
    _stopPing();
    // 每 25 秒發送一個空消息作為心跳
    _pingTimer = Timer.periodic(Duration(seconds: 25), (timer) {
      if (_channel != null) {
        try {
          print('💓 [WebSocket] 發送心跳');
          // 發送一個空的 JSON 對象作為心跳
          _channel!.sink.add(jsonEncode({'type': 'ping'}));
        } catch (e) {
          print('❌ [WebSocket] 心跳發送失敗: $e');
        }
      }
    });
  }

  void _stopPing() {
    _pingTimer?.cancel();
    _pingTimer = null;
  }

  Future<void> sendMessage(String message) async {
    if (_channel != null) {
      _channel!.sink.add(jsonEncode({'message': message}));
    }
  }

  void disconnect() {
    print('🔌 [WebSocket] 斷開連接');
    _stopPing();
    _channel?.sink.close();
    _channel = null;
  }

  void dispose() {
    _stopPing();
    _messageController.close();
    _roomClosedController.close();
    _streamStoppedController.close();
    _streamStartedController.close();
  }
}
