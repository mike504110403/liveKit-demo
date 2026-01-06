import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:fijkplayer/fijkplayer.dart';

// Web 專用導入（只在 Web 平台使用）
// ignore: avoid_web_libraries_in_flutter
import 'dart:js' as js;

/// 自適應視頻播放器
/// Web: 使用 iframe + flv.js + FLV
/// Mobile: 使用 fijkplayer + FLV
class AdaptiveVideoPlayer extends StatefulWidget {
  final String hlsUrl; // HLS URL (備用)
  final String flvUrl; // FLV URL (主要)
  final VoidCallback? onError;
  final VoidCallback? onReady;

  const AdaptiveVideoPlayer({
    super.key,
    required this.hlsUrl,
    required this.flvUrl,
    this.onError,
    this.onReady,
  });

  @override
  State<AdaptiveVideoPlayer> createState() => _AdaptiveVideoPlayerState();
}

class _AdaptiveVideoPlayerState extends State<AdaptiveVideoPlayer> {
  // fijkplayer (Mobile + FLV)
  FijkPlayer? _fijkPlayer;

  // Web iframe 播放器
  String? _iframeViewType;

  bool _isInitialized = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    try {
      if (kIsWeb) {
        // Web 平台：使用 iframe + flv.js + FLV
        await _initializeWebFLVPlayer();
      } else {
        // Mobile 平台：使用 fijkplayer + FLV
        await _initializeFijkPlayer();
      }
    } catch (e) {
      print('❌ [播放器] 初始化失敗: $e');
      setState(() {
        _hasError = true;
      });
      widget.onError?.call();
    }
  }

  /// 初始化 Web FLV 播放器 (使用 iframe + flv.js)
  Future<void> _initializeWebFLVPlayer() async {
    print('🌐 [播放器] Web 平台 - 使用 iframe + flv.js + FLV');
    print('📍 [播放器] URL: ${widget.flvUrl}');

    // 生成唯一的 view type
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    _iframeViewType = 'flv-player-$timestamp';

    // 使用 js context 註冊 iframe（兼容所有 Flutter 版本）
    try {
      // ignore: avoid_dynamic_calls
      final result = js.context.callMethod('eval', [
        '''
        (function() {
          console.log('[AdaptiveVideoPlayer] 開始註冊視圖...');
          console.log('[AdaptiveVideoPlayer] viewType:', "$_iframeViewType");
          
          if (typeof window.platformViewRegistry === 'undefined') {
            console.error('[AdaptiveVideoPlayer] window.platformViewRegistry 不存在！');
            return false;
          }
          
          console.log('[AdaptiveVideoPlayer] platformViewRegistry 存在');
          
          window.platformViewRegistry.registerViewFactory(
            "$_iframeViewType",
            function(viewId) {
              console.log('[AdaptiveVideoPlayer] 創建 iframe, viewId:', viewId);
              const iframe = document.createElement('iframe');
              iframe.src = '/flv_player.html?url=${Uri.encodeComponent(widget.flvUrl)}';
              iframe.style.border = 'none';
              iframe.style.width = '100%';
              iframe.style.height = '100%';
              iframe.allow = 'autoplay';
              console.log('[AdaptiveVideoPlayer] iframe 已創建:', iframe.src);
              return iframe;
            }
          );
          
          console.log('[AdaptiveVideoPlayer] 視圖註冊成功！');
          return true;
        })()
      '''
      ]);

      print('✅ [播放器] JavaScript 註冊結果: $result');

      if (result != true) {
        throw Exception('platformViewRegistry 註冊失敗');
      }
    } catch (e) {
      print('❌ [播放器] 註冊 view factory 失敗: $e');
      setState(() {
        _hasError = true;
      });
      widget.onError?.call();
      return;
    }

    setState(() {
      _isInitialized = true;
    });

    print('✅ [播放器] Web FLV 播放器 (iframe) 初始化成功');
    widget.onReady?.call();
  }

  /// 初始化 fijkplayer (Mobile + FLV)
  Future<void> _initializeFijkPlayer() async {
    print('📱 [播放器] Mobile 平台 - 使用 fijkplayer + FLV');
    print('📍 [播放器] URL: ${widget.flvUrl}');

    _fijkPlayer = FijkPlayer();

    // 設置選項
    _fijkPlayer!.setOption(FijkOption.hostCategory, "request-screen-on", 1);
    _fijkPlayer!.setOption(FijkOption.hostCategory, "request-audio-focus", 1);

    // 播放器配置
    _fijkPlayer!.setOption(FijkOption.playerCategory, "mediacodec", 1);
    _fijkPlayer!.setOption(FijkOption.playerCategory, "mediacodec-auto-rotate", 1);
    _fijkPlayer!.setOption(FijkOption.playerCategory, "mediacodec-handle-resolution-change", 1);

    // 格式配置（FLV）
    _fijkPlayer!.setOption(FijkOption.formatCategory, "analyzeduration", 1);
    _fijkPlayer!.setOption(FijkOption.formatCategory, "flush_packets", 1);
    _fijkPlayer!.setOption(FijkOption.formatCategory, "fflags", "nobuffer");
    _fijkPlayer!.setOption(FijkOption.formatCategory, "rtsp_transport", "tcp");

    // 編解碼器配置
    _fijkPlayer!.setOption(FijkOption.codecCategory, "skip_loop_filter", 48);

    // 低延遲配置
    _fijkPlayer!.setOption(FijkOption.playerCategory, "max_cached_duration", 3000); // 3秒緩存
    _fijkPlayer!.setOption(FijkOption.playerCategory, "infbuf", 1);
    _fijkPlayer!.setOption(FijkOption.playerCategory, "packet-buffering", 0);

    // 設置數據源
    await _fijkPlayer!.setDataSource(
      widget.flvUrl,
      autoPlay: true,
      showCover: false,
    );

    // 監聽狀態變化
    _fijkPlayer!.addListener(_onFijkPlayerStateChanged);

    setState(() {
      _isInitialized = true;
    });

    print('✅ [播放器] fijkplayer 初始化成功');
    widget.onReady?.call();
  }

  void _onFijkPlayerStateChanged() {
    if (_fijkPlayer == null) return;

    FijkState state = _fijkPlayer!.state;

    if (state == FijkState.error) {
      print('❌ [播放器] fijkplayer 錯誤');
      setState(() {
        _hasError = true;
      });
      widget.onError?.call();
    } else if (state == FijkState.prepared) {
      print('✅ [播放器] fijkplayer 準備完成');
    } else if (state == FijkState.started) {
      print('▶️  [播放器] fijkplayer 開始播放');
    }
  }

  @override
  void dispose() {
    print('🗑️ [播放器] 清理資源...');

    // 清理 Mobile 播放器
    _fijkPlayer?.removeListener(_onFijkPlayerStateChanged);
    _fijkPlayer?.release();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return Container(
        color: Colors.black,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, color: Colors.red, size: 48),
              SizedBox(height: 16),
              Text(
                '播放器錯誤',
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
              SizedBox(height: 8),
              Text(
                kIsWeb ? '請檢查網絡連接和直播流' : '無法播放視頻',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    if (!_isInitialized) {
      return Container(
        color: Colors.black,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Colors.white),
              SizedBox(height: 16),
              Text(
                '正在初始化播放器...',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
      );
    }

    // 根據平台返回不同的播放器 Widget
    if (kIsWeb) {
      return _buildWebFLVPlayer();
    } else {
      return _buildFijkPlayer();
    }
  }

  /// Web FLV 播放器 Widget (iframe)
  Widget _buildWebFLVPlayer() {
    if (_iframeViewType == null) {
      return Container(
        color: Colors.black,
        child: Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    return Container(
      color: Colors.black,
      child: HtmlElementView(
        viewType: _iframeViewType!,
      ),
    );
  }

  /// fijkplayer Widget
  Widget _buildFijkPlayer() {
    if (_fijkPlayer == null) {
      return Container(
        color: Colors.black,
        child: Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    return FijkView(
      player: _fijkPlayer!,
      color: Colors.black,
      fit: FijkFit.contain,
      fsFit: FijkFit.contain,
      panelBuilder:
          (FijkPlayer player, FijkData data, BuildContext context, Size viewSize, Rect texturePos) {
        // 簡單的控制面板（可選）
        return Container();
      },
    );
  }
}
