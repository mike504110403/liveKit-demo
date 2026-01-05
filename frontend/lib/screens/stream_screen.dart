import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import '../models/user.dart';
import '../models/chat_message.dart';
import '../services/websocket_service.dart';
import '../services/agora_service.dart';
import '../widgets/chat_widget.dart';
import '../config/app_config.dart';

class StreamScreen extends StatefulWidget {
  final User user;
  final String roomId;
  final String title;
  final String rtmpUrl;
  final String streamKey;

  const StreamScreen({
    super.key,
    required this.user,
    required this.roomId,
    required this.title,
    required this.rtmpUrl,
    required this.streamKey,
  });

  @override
  _StreamScreenState createState() => _StreamScreenState();
}

class _StreamScreenState extends State<StreamScreen> {
  /// 構建控制按鈕
  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onPressed,
    bool isActive = true,
  }) {
    return FloatingActionButton(
      mini: true,
      onPressed: onPressed,
      backgroundColor: isActive ? Colors.white : Colors.grey,
      foregroundColor: Colors.black,
      child: Icon(icon),
    );
  }

  final _wsService = WebSocketService();
  final _agoraService = AgoraService.instance;
  final List<ChatMessage> _messages = [];

  bool _isStreaming = false;
  bool _isMuted = false;
  bool _isCameraOff = false;
  bool _isFrontCamera = true;
  bool _isBeautyOn = false;
  bool _showChat = true;
  bool _isInitialized = false;
  String _statusText = '準備中...';

  @override
  void initState() {
    super.initState();
    _initializeAgora();
    _connectWebSocket();
  }

  /// 初始化 Agora
  Future<void> _initializeAgora() async {
    setState(() => _statusText = '正在初始化...');

    // 檢查 App ID
    if (AppConfig.agoraAppId.isEmpty) {
      setState(() {
        _statusText = '❌ 未配置 Agora App ID';
        _isInitialized = false;
      });
      _showConfigGuide();
      return;
    }

    // 請求權限
    final hasPermission = await _agoraService.requestPermissions();
    if (!hasPermission) {
      setState(() => _statusText = '❌ 需要相機和麥克風權限');
      return;
    }

    // 初始化引擎
    final initialized = await _agoraService.initialize();
    if (!initialized) {
      setState(() => _statusText = '❌ 初始化失敗');
      return;
    }

    // 開始預覽
    final previewStarted = await _agoraService.startPreview();
    if (!previewStarted) {
      setState(() => _statusText = '❌ 預覽啟動失敗');
      return;
    }

    setState(() {
      _isInitialized = true;
      _statusText = '準備就緒 - 點擊開始直播';
    });
  }

  /// 顯示配置指南
  void _showConfigGuide() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('配置 Agora App ID'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('請按以下步驟配置：\n'),
              Text('1. 前往 https://console.agora.io/'),
              Text('2. 註冊/登入帳號（可用 Email 或 Google）'),
              Text('3. 創建項目，獲取 App ID'),
              Text('4. 編輯 frontend/lib/config/app_config.dart'),
              Text('5. 填入你的 Agora App ID\n'),
              Text('提示：台灣用戶可直接註冊使用',
                  style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('確定'),
          ),
        ],
      ),
    );
  }

  /// 連接 WebSocket
  Future<void> _connectWebSocket() async {
    try {
      await _wsService.connect(widget.roomId, widget.user.token);
      _wsService.messages.listen((message) {
        setState(() => _messages.add(message));
      });
    } catch (e) {
      print('WebSocket 連接失敗: $e');
    }
  }

  /// 開始/停止直播
  Future<void> _toggleStreaming() async {
    if (!_isInitialized) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('請先完成初始化')),
      );
      return;
    }

    if (_isStreaming) {
      // 停止直播
      await _agoraService.leaveChannel();
      setState(() {
        _isStreaming = false;
        _statusText = '已停止直播';
      });
    } else {
      // 開始直播
      setState(() => _statusText = '正在連接...');

      // 使用 roomId 作為頻道名稱
      final success = await _agoraService.joinChannel(widget.roomId);

      if (success) {
        // 可選：推流到自定義 RTMP 地址
        if (AppConfig.enableOBSMode && widget.rtmpUrl.isNotEmpty) {
          await _agoraService.addPublishStreamUrl(
            widget.rtmpUrl,
            widget.streamKey,
          );
        }

        setState(() {
          _isStreaming = true;
          _statusText = '🔴 直播中';
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('開始直播！'), backgroundColor: Colors.green),
        );
      } else {
        setState(() => _statusText = '❌ 連接失敗');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('直播啟動失敗'), backgroundColor: Colors.red),
        );
      }
    }
  }

  /// 切換攝像頭
  Future<void> _switchCamera() async {
    await _agoraService.switchCamera();
    setState(() {
      _isFrontCamera = !_isFrontCamera;
    });
  }

  /// 靜音/取消靜音
  Future<void> _toggleMute() async {
    await _agoraService.muteAudio(!_isMuted);
    setState(() {
      _isMuted = !_isMuted;
    });
  }

  /// 開關攝像頭
  Future<void> _toggleCamera() async {
    await _agoraService.muteVideo(!_isCameraOff);
    setState(() {
      _isCameraOff = !_isCameraOff;
    });
  }

  /// 切換美顏
  Future<void> _toggleBeauty() async {
    if (!AppConfig.enableBeauty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('美顏功能未啟用')),
      );
      return;
    }

    await _agoraService.enableBeautify(!_isBeautyOn);
    setState(() {
      _isBeautyOn = !_isBeautyOn;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_isBeautyOn ? '✨ 美顏已開啟' : '美顏已關閉')),
    );
  }

  /// 發送聊天訊息
  Future<void> _sendMessage(String content) async {
    try {
      await _wsService.sendMessage(content);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('發送失敗: $e')),
      );
    }
  }

  /// 複製推流地址
  void _copyStreamUrl() {
    Clipboard.setData(ClipboardData(text: widget.rtmpUrl));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('已複製推流地址')),
    );
  }

  @override
  void dispose() {
    _agoraService.dispose();
    _wsService.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          // 切換聊天窗口
          IconButton(
            icon: Icon(_showChat ? Icons.chat : Icons.chat_bubble_outline),
            onPressed: () => setState(() => _showChat = !_showChat),
          ),
          // 複製推流地址
          if (AppConfig.enableOBSMode)
            IconButton(
              icon: Icon(Icons.copy),
              onPressed: _copyStreamUrl,
              tooltip: '複製 RTMP 地址',
            ),
        ],
      ),
      body: Column(
        children: [
          // 預覽區域
          Expanded(
            child: Container(
              color: Colors.black,
              child: _isInitialized
                  ? Stack(
                      children: [
                        // Agora 視頻預覽
                        Positioned.fill(
                          child: AgoraVideoView(
                            controller: VideoViewController(
                              rtcEngine: _agoraService.engine!,
                              canvas: const VideoCanvas(uid: 0),
                            ),
                          ),
                        ),
                        // 狀態顯示
                        Positioned(
                          top: 16,
                          left: 16,
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: _isStreaming ? Colors.red.withOpacity(0.8) : Colors.black54,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              _statusText,
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        // 控制按鈕
                        Positioned(
                          bottom: 16,
                          left: 0,
                          right: 0,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // 切換攝像頭
                              _buildControlButton(
                                icon: Icons.cameraswitch,
                                onPressed: _switchCamera,
                              ),
                              SizedBox(width: 12),
                              // 靜音
                              _buildControlButton(
                                icon: _isMuted ? Icons.mic_off : Icons.mic,
                                onPressed: _toggleMute,
                                isActive: !_isMuted,
                              ),
                              SizedBox(width: 12),
                              // 攝像頭開關
                              _buildControlButton(
                                icon: _isCameraOff ? Icons.videocam_off : Icons.videocam,
                                onPressed: _toggleCamera,
                                isActive: !_isCameraOff,
                              ),
                              SizedBox(width: 12),
                              // 美顏
                              if (AppConfig.enableBeauty)
                                _buildControlButton(
                                  icon: Icons.face,
                                  onPressed: _toggleBeauty,
                                  isActive: _isBeautyOn,
                                ),
                            ],
                          ),
                        ),
                      ],
                    )
                  : Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(color: Colors.white),
                          SizedBox(height: 16),
                          Text(
                            _statusText,
                            style: TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
            ),
          ),
          // 聊天區域
          if (_showChat)
            Container(
              height: 200,
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: Colors.grey.shade300)),
              ),
              child: ChatWidget(
                messages: _messages,
                onSendMessage: _sendMessage,
              ),
            ),
          // 開始直播按鈕
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16),
            child: ElevatedButton(
              onPressed: _isInitialized ? _toggleStreaming : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: _isStreaming ? Colors.red : Colors.blue,
                padding: EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(
                _isStreaming ? '停止直播' : '開始直播',
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
