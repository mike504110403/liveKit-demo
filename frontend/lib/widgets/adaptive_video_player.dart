import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:video_player/video_player.dart';
import 'package:fijkplayer/fijkplayer.dart';

/// 自適應視頻播放器
/// Web: 使用 video_player + HLS
/// Mobile: 使用 fijkplayer + FLV
class AdaptiveVideoPlayer extends StatefulWidget {
  final String hlsUrl;
  final String flvUrl;
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
  VideoPlayerController? _videoController;
  FijkPlayer? _fijkPlayer;

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
        await _initializeVideoPlayer();
      } else {
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

  /// 初始化 video_player (Web + HLS)
  Future<void> _initializeVideoPlayer() async {
    print('🌐 [播放器] Web 平台 - 使用 video_player + HLS');
    print('📍 [播放器] URL: ${widget.hlsUrl}');

    _videoController = VideoPlayerController.networkUrl(
      Uri.parse(widget.hlsUrl),
      videoPlayerOptions: VideoPlayerOptions(
        mixWithOthers: true,
        allowBackgroundPlayback: false,
      ),
      httpHeaders: {
        'Accept': '*/*',
        'Cache-Control': 'no-cache, no-store, must-revalidate',
        'Pragma': 'no-cache',
        'Expires': '0',
      },
    );

    await _videoController!.initialize();
    await _videoController!.setLooping(true);
    await _videoController!.setVolume(1.0);
    await _videoController!.play();

    setState(() {
      _isInitialized = true;
    });

    print('✅ [播放器] video_player 初始化成功');
    widget.onReady?.call();
  }

  /// 初始化 fijkplayer (Mobile + FLV)
  Future<void> _initializeFijkPlayer() async {
    print('📱 [播放器] Mobile 平台 - 使用 fijkplayer + FLV');
    print('📍 [播放器] URL: ${widget.flvUrl}');

    _fijkPlayer = FijkPlayer();

    _fijkPlayer!.setOption(FijkOption.hostCategory, "request-screen-on", 1);
    _fijkPlayer!.setOption(FijkOption.hostCategory, "request-audio-focus", 1);
    _fijkPlayer!.setOption(FijkOption.playerCategory, "mediacodec", 1);
    _fijkPlayer!.setOption(FijkOption.formatCategory, "analyzeduration", 1);
    _fijkPlayer!.setOption(FijkOption.formatCategory, "flush_packets", 1);
    _fijkPlayer!.setOption(FijkOption.formatCategory, "fflags", "nobuffer");
    _fijkPlayer!.setOption(FijkOption.codecCategory, "skip_loop_filter", 48);
    _fijkPlayer!.setOption(FijkOption.playerCategory, "max_cached_duration", 3000);

    await _fijkPlayer!.setDataSource(
      widget.flvUrl,
      autoPlay: true,
      showCover: false,
    );

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
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
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
              Text('播放器錯誤', style: TextStyle(color: Colors.white)),
            ],
          ),
        ),
      );
    }

    if (!_isInitialized) {
      return Container(
        color: Colors.black,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (kIsWeb) {
      return _buildVideoPlayer();
    } else {
      return _buildFijkPlayer();
    }
  }

  Widget _buildVideoPlayer() {
    if (_videoController == null || !_videoController!.value.isInitialized) {
      return Container(
        color: Colors.black,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return Center(
      child: AspectRatio(
        aspectRatio: _videoController!.value.aspectRatio,
        child: VideoPlayer(_videoController!),
      ),
    );
  }

  Widget _buildFijkPlayer() {
    if (_fijkPlayer == null) {
      return Container(
        color: Colors.black,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return FijkView(
      player: _fijkPlayer!,
      color: Colors.black,
      fit: FijkFit.contain,
      fsFit: FijkFit.contain,
      panelBuilder: (player, data, context, viewSize, texturePos) => Container(),
    );
  }
}
