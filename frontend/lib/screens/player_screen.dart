import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:video_player/video_player.dart';
import 'dart:async';
import '../models/user.dart';
import '../models/room.dart';
import '../models/chat_message.dart';
import '../services/api_service.dart';
import '../services/websocket_service.dart';
import '../widgets/chat_widget.dart';
import '../widgets/adaptive_video_player.dart';
import 'stream_screen.dart';

class PlayerScreen extends StatefulWidget {
  final User user;
  final Room room;

  const PlayerScreen({super.key, required this.user, required this.room});

  @override
  _PlayerScreenState createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  final _apiService = ApiService();
  final _wsService = WebSocketService();
  final List<ChatMessage> _messages = [];

  // video_player (Web + HLS) - 備用
  VideoPlayerController? _controller;

  bool _loading = true;
  String? _error;
  bool _isHost = false;
  String _roomStatus = 'idle';
  int _retryCount = 0;
  static const int _maxRetries = 3;
  Timer? _retryTimer;
  String? _hlsUrl; // 儲存 HLS URL for Web iframe
  String? _flvUrl; // 儲存 FLV URL for Mobile

  // WebSocket 訂閱
  StreamSubscription? _messageSubscription;
  StreamSubscription? _roomClosedSubscription;
  StreamSubscription? _streamStoppedSubscription;
  StreamSubscription? _streamStartedSubscription;

  @override
  void initState() {
    super.initState();
    _isHost = widget.user.id == widget.room.hostId;
    _roomStatus = widget.room.status;
    _initPlayer();

    // 監聽聊天消息
    _messageSubscription = _wsService.messages.listen((message) {
      if (mounted) {
        setState(() => _messages.add(message));
      }
    });

    // 監聽房間關閉事件
    _roomClosedSubscription = _wsService.onRoomClosed.listen((message) {
      print('🚪 [播放器] 房間已關閉: $message');
      if (mounted) {
        // 完全清理播放器資源
        _cleanupPlayer();

        // 顯示提示並立即返回首頁
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$message，即將返回首頁'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );

        // 延遲返回，讓用戶看到提示
        Future.delayed(Duration(milliseconds: 1500), () {
          if (mounted) {
            Navigator.of(context).pop();
          }
        });
      }
    });

    // 監聽停止直播事件
    _streamStoppedSubscription = _wsService.onStreamStopped.listen((message) {
      print('⏹️  [播放器] 直播已停止: $message');
      if (mounted && !_isHost) {
        // 完全清理播放器資源
        _cleanupPlayer();

        // 更新狀態
        setState(() {
          _roomStatus = 'idle';
          _error = 'stream_stopped';
          _loading = false;
        });

        // 顯示提示
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
      }
    });

    // 監聽開始直播事件
    _streamStartedSubscription = _wsService.onStreamStarted.listen((message) {
      print('▶️  [播放器] 直播已開始: $message');
      if (mounted && !_isHost) {
        // 重新初始化播放器
        setState(() {
          _roomStatus = 'live';
          _error = null;
          _loading = true;
          _retryCount = 0;
        });

        // 重新初始化播放器
        _initPlayer();

        // 顯示提示
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    });

    _wsService.connect(widget.room.id, widget.user.token);
  }

  Future<void> _initPlayer() async {
    print('🎬 [播放器] 開始初始化，重試次數: $_retryCount/$_maxRetries');
    print('🎬 [播放器] 平台: ${kIsWeb ? "Web (使用 hls.js)" : "移動端 (使用 video_player)"}');

    // 如果是房主，不載入播放器
    if (_isHost) {
      setState(() {
        _loading = false;
        _error = null;
      });
      return;
    }

    // 如果房間還沒開始直播，不載入播放器
    if (_roomStatus != 'live') {
      setState(() {
        _loading = false;
        _error = null;
      });
      return;
    }

    // 防止重複初始化
    if (_controller != null && _controller!.value.isInitialized) {
      print('🎬 [播放器] 已初始化，跳過');
      return;
    }

    // 超過最大重試次數
    if (_retryCount >= _maxRetries) {
      print('❌ [播放器] 達到最大重試次數');
      if (mounted) {
        setState(() {
          _error = 'max_retries';
          _loading = false;
        });
      }
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      print('📡 [播放器] 獲取播放地址...');
      final urls = await _apiService.getPlayUrls(widget.room.id);

      // 儲存 URLs 供 AdaptiveVideoPlayer 使用
      if (mounted) {
        setState(() {
          _hlsUrl = urls.hls;
          _flvUrl = urls.flv;
          _loading = false;
          _error = null;
          _retryCount = 0;
        });
      }

      print('✅ [播放器] 取得播放地址:');
      print('   - HLS: ${urls.hls}');
      print('   - FLV: ${urls.flv}');
      print('   - 平台: ${kIsWeb ? "Web (HLS)" : "Mobile (FLV)"}');
      print('✅ [播放器] AdaptiveVideoPlayer 將自動選擇適合的播放器');
    } catch (e) {
      print('❌ [播放器] 初始化失敗: $e');

      if (!mounted) return;

      _retryCount++;

      // 如果還沒達到最大重試次數，安排自動重試
      if (_retryCount < _maxRetries) {
        print('🔄 [播放器] 將在 3 秒後重試 ($_retryCount/$_maxRetries)');
        setState(() {
          _error = 'retrying';
          _loading = false;
        });

        // 取消之前的定時器
        _retryTimer?.cancel();

        // 3 秒後自動重試
        _retryTimer = Timer(Duration(seconds: 3), () {
          if (mounted && _roomStatus == 'live') {
            _initPlayer();
          }
        });
      } else {
        print('❌ [播放器] 達到最大重試次數');
        setState(() {
          _error = 'max_retries';
          _loading = false;
        });
      }
    }
  }

  Future<void> _updateRoomStatus(String status) async {
    try {
      await _apiService.updateRoomStatus(
        widget.user.token,
        widget.room.id,
        status,
      );

      setState(() {
        _roomStatus = status;
        _loading = true;
        _error = null;
      });

      // 停止當前播放器
      if (_controller != null) {
        await _controller!.dispose();
        _controller = null;
      }

      // 重新初始化播放器
      await _initPlayer();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(status == 'live' ? '直播已開始' : '直播已停止')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('操作失敗: $e')),
      );
    }
  }

  void _showStreamInfo() {
    final rtmpUrl = 'rtmp://localhost:1935/live/${widget.room.streamKey}';
    final playUrl = 'http://localhost:8080/live/${widget.room.streamKey}.m3u8';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('推流資訊'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('RTMP 推流地址：', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 4),
              SelectableText(
                rtmpUrl,
                style: TextStyle(fontSize: 12, fontFamily: 'monospace'),
              ),
              SizedBox(height: 16),
              Text('Stream Key：', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 4),
              SelectableText(
                widget.room.streamKey,
                style: TextStyle(fontSize: 12, fontFamily: 'monospace'),
              ),
              SizedBox(height: 16),
              Text('播放地址：', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 4),
              SelectableText(
                playUrl,
                style: TextStyle(fontSize: 12, fontFamily: 'monospace'),
              ),
              SizedBox(height: 16),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '💡 提示：使用 OBS 推流時，將 RTMP 地址和 Stream Key 分別填入對應欄位',
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('關閉'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteRoom() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('確認刪除'),
        content: Text('確定要關閉直播間嗎？此操作無法撤銷。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('確定', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _apiService.deleteRoom(widget.user.token, widget.room.id);
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('直播間已關閉')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('刪除失敗: $e')),
        );
      }
    }
  }

  Widget _buildHostControlPanel() {
    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 狀態指示器
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: _roomStatus == 'live' ? Colors.red : Colors.grey,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_roomStatus == 'live')
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                  if (_roomStatus == 'live') SizedBox(width: 8),
                  Text(
                    _roomStatus == 'live' ? '直播中' : '未開播',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 32),

            // 圖標
            Icon(
              _roomStatus == 'live' ? Icons.videocam : Icons.videocam_off,
              size: 80,
              color: _roomStatus == 'live' ? Colors.red : Colors.white54,
            ),

            SizedBox(height: 24),

            // 標題
            Text(
              _roomStatus == 'live' ? '正在直播' : '推流控制面板',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            SizedBox(height: 16),

            // 說明文字
            Text(
              _roomStatus == 'live' ? '使用 OBS 推流中...' : '使用 OBS 或其他推流工具開始直播',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),

            SizedBox(height: 32),

            // 推流資訊卡片
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.stream, color: Colors.blue, size: 20),
                      SizedBox(width: 8),
                      Text(
                        '推流設定',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  _buildInfoRow('伺服器', 'rtmp://localhost:1935/live'),
                  SizedBox(height: 8),
                  _buildInfoRow('串流金鑰', widget.room.streamKey),
                  SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _showStreamInfo,
                      icon: Icon(Icons.content_copy, size: 18),
                      label: Text('複製推流資訊'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: BorderSide(color: Colors.white54),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 32),

            // 選擇推流方式（僅在未開播時顯示）
            if (_roomStatus == 'idle') ...[
              Text(
                '選擇推流方式：',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16),
              // OBS 推流按鈕
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _updateRoomStatus('live'),
                  icon: Icon(Icons.desktop_windows, size: 24),
                  label: Text(
                    '使用 OBS 推流',
                    style: TextStyle(fontSize: 18),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 12),
              // 鏡頭推流按鈕
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    try {
                      // 先更新房間狀態為 live
                      await _apiService.updateRoomStatus(
                        widget.user.token,
                        widget.room.id,
                        'live',
                      );
                      setState(() => _roomStatus = 'live');

                      // 跳轉到鏡頭推流頁面
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => StreamScreen(
                            user: widget.user,
                            roomId: widget.room.id,
                            title: widget.room.title,
                            rtmpUrl: 'rtmp://localhost:1935/live',
                            streamKey: widget.room.streamKey,
                          ),
                        ),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('操作失敗: $e')),
                      );
                    }
                  },
                  icon: Icon(Icons.videocam, size: 24),
                  label: Text(
                    '使用鏡頭推流',
                    style: TextStyle(fontSize: 18),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
            // 停止直播按鈕（僅在直播中顯示）
            if (_roomStatus == 'live')
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    _updateRoomStatus('idle');
                  },
                  icon: Icon(Icons.stop, size: 24),
                  label: Text(
                    '停止直播',
                    style: TextStyle(fontSize: 18),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),

            SizedBox(height: 16),

            // 提示
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue, size: 20),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '點擊「開始直播」後，在 OBS 開始推流',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 70,
          child: Text(
            '$label:',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontFamily: 'monospace',
            ),
          ),
        ),
      ],
    );
  }

  /// 完全清理播放器資源
  void _cleanupPlayer() {
    print('🧹 [播放器] 完全清理播放器資源...');

    // 取消重試定時器
    _retryTimer?.cancel();
    _retryTimer = null;

    // 清理 URLs
    _hlsUrl = null;
    _flvUrl = null;

    // 清理 video_player (舊的，備用)
    if (_controller != null) {
      _controller!.pause();
      _controller!.dispose();
      _controller = null;
    }

    // 清理 fijkplayer (由 AdaptiveVideoPlayer 自動處理)

    // 重置重試計數
    _retryCount = 0;
  }

  /// 構建 Web 播放器 (iframe + hls.js)
  // _buildWebPlayer 已移除，改用 AdaptiveVideoPlayer

  @override
  void dispose() {
    print('🗑️  [播放器] 清理資源...');
    _cleanupPlayer();
    _messageSubscription?.cancel();
    _roomClosedSubscription?.cancel();
    _streamStoppedSubscription?.cancel();
    _streamStartedSubscription?.cancel();
    _wsService.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.room.title),
        actions: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.visibility, size: 20),
                SizedBox(width: 4),
                Text('${widget.room.viewerCount}'),
              ],
            ),
          ),
          // 房主控制選單
          if (_isHost)
            PopupMenuButton<String>(
              onSelected: (value) {
                switch (value) {
                  case 'start':
                    _updateRoomStatus('live');
                    break;
                  case 'stop':
                    _updateRoomStatus('idle');
                    break;
                  case 'stream_info':
                    _showStreamInfo();
                    break;
                  case 'delete':
                    _deleteRoom();
                    break;
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'start',
                  enabled: _roomStatus == 'idle',
                  child: Row(
                    children: [
                      Icon(Icons.play_arrow, color: Colors.green),
                      SizedBox(width: 8),
                      Text('開始直播'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'stop',
                  enabled: _roomStatus == 'live',
                  child: Row(
                    children: [
                      Icon(Icons.stop, color: Colors.orange),
                      SizedBox(width: 8),
                      Text('停止直播'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'stream_info',
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue),
                      SizedBox(width: 8),
                      Text('推流資訊'),
                    ],
                  ),
                ),
                PopupMenuDivider(),
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: Colors.red),
                      SizedBox(width: 8),
                      Text('關閉直播間', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: Column(
        children: [
          // 視頻播放器 / 房主控制面板
          Expanded(
            flex: 2,
            child: Container(
              color: Colors.black,
              child: _loading
                  ? Center(child: CircularProgressIndicator())
                  : _isHost
                      ? _buildHostControlPanel()
                      : _roomStatus != 'live'
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.tv_off,
                                    size: 64,
                                    color: Colors.white54,
                                  ),
                                  SizedBox(height: 16),
                                  Text(
                                    '直播尚未開始',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    '等待主播開始直播...',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : _error != null
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        _error == 'retrying'
                                            ? Icons.hourglass_empty
                                            : _error == 'max_retries'
                                                ? Icons.error_outline
                                                : _error == 'stream_stopped'
                                                    ? Icons.stop_circle_outlined
                                                    : Icons.live_tv_outlined,
                                        size: 64,
                                        color: _error == 'retrying'
                                            ? Colors.blue
                                            : _error == 'max_retries'
                                                ? Colors.red
                                                : _error == 'stream_stopped'
                                                    ? Colors.orange
                                                    : Colors.orange,
                                      ),
                                      SizedBox(height: 16),
                                      Text(
                                        _error == 'retrying'
                                            ? '正在重試...'
                                            : _error == 'max_retries'
                                                ? '載入失敗'
                                                : _error == 'stream_stopped'
                                                    ? '直播已停止'
                                                    : '等待推流中...',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      SizedBox(height: 8),
                                      Padding(
                                        padding: EdgeInsets.symmetric(horizontal: 32),
                                        child: Text(
                                          _error == 'retrying'
                                              ? '正在嘗試連接播放器... ($_retryCount/$_maxRetries)'
                                              : _error == 'max_retries'
                                                  ? '推流可能尚未開始或網絡連接有問題\n請確認 OBS 已開始推流'
                                                  : _error == 'stream_stopped'
                                                      ? '主播已停止直播\n畫面已清除，等待主播重新開始...'
                                                      : _isHost
                                                          ? '請使用 OBS 或其他推流工具開始推流\nRTMP 地址請查看直播間詳情'
                                                          : '主播正在準備中，請稍候...',
                                          style: TextStyle(
                                            color: Colors.white70,
                                            fontSize: 14,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                      if (_error == 'max_retries')
                                        Padding(
                                          padding: EdgeInsets.only(top: 16),
                                          child: ElevatedButton.icon(
                                            onPressed: () {
                                              setState(() {
                                                _retryCount = 0;
                                                _error = null;
                                              });
                                              _initPlayer();
                                            },
                                            icon: Icon(Icons.refresh),
                                            label: Text('手動重試'),
                                          ),
                                        ),
                                    ],
                                  ),
                                )
                              : (_hlsUrl != null && _flvUrl != null)
                                  ? AdaptiveVideoPlayer(
                                      hlsUrl: _hlsUrl!,
                                      flvUrl: _flvUrl!,
                                      onError: () {
                                        if (mounted) {
                                          setState(() {
                                            _error = 'player_error';
                                            _loading = false;
                                          });
                                        }
                                      },
                                      onReady: () {
                                        print('✅ [播放器] 自適應播放器準備完成');
                                      },
                                    )
                                  : _controller != null && _controller!.value.isInitialized
                                      ? AspectRatio(
                                          aspectRatio: _controller!.value.aspectRatio,
                                          child: VideoPlayer(_controller!),
                                        )
                                      : Center(child: CircularProgressIndicator()),
            ),
          ),

          // 聊天室
          Expanded(
            flex: 1,
            child: ChatWidget(
              messages: _messages,
              onSendMessage: _wsService.sendMessage,
            ),
          ),
        ],
      ),
    );
  }
}
