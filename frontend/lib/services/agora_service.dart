import 'dart:developer' as developer;
import 'package:permission_handler/permission_handler.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import '../config/app_config.dart';

/// Agora 推流服務
class AgoraService {
  static AgoraService? _instance;
  RtcEngine? _engine;
  bool _isInitialized = false;
  bool _isStreaming = false;
  bool _isFrontCamera = true;
  
  AgoraService._();
  
  static AgoraService get instance {
    _instance ??= AgoraService._();
    return _instance!;
  }
  
  bool get isStreaming => _isStreaming;
  bool get isFrontCamera => _isFrontCamera;
  RtcEngine? get engine => _engine;
  
  /// 初始化 Agora Engine
  Future<bool> initialize() async {
    if (_isInitialized) {
      developer.log('Agora already initialized');
      return true;
    }
    
    if (AppConfig.agoraAppId.isEmpty) {
      developer.log('Agora App ID not configured', name: 'AgoraService');
      return false;
    }
    
    try {
      // 創建引擎
      _engine = createAgoraRtcEngine();
      
      await _engine!.initialize(RtcEngineContext(
        appId: AppConfig.agoraAppId,
        channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
      ));
      
      // 設置為主播角色（推流）
      await _engine!.setClientRole(role: ClientRoleType.clientRoleBroadcaster);
      
      // 啟用視頻
      await _engine!.enableVideo();
      
      // 啟用音頻
      await _engine!.enableAudio();
      
      // 設置視頻編碼配置
      await _engine!.setVideoEncoderConfiguration(
        const VideoEncoderConfiguration(
          dimensions: VideoDimensions(width: 1280, height: 720),
          frameRate: 30,
          bitrate: 2000,
          orientationMode: OrientationMode.orientationModeFixedPortrait,
        ),
      );
      
      _isInitialized = true;
      developer.log('Agora initialized successfully', name: 'AgoraService');
      return true;
    } catch (e) {
      developer.log('Agora initialization failed: $e', name: 'AgoraService');
      return false;
    }
  }
  
  /// 請求權限
  Future<bool> requestPermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.camera,
      Permission.microphone,
    ].request();

    bool granted = statuses[Permission.camera]!.isGranted &&
        statuses[Permission.microphone]!.isGranted;
        
    if (!granted) {
      developer.log('Camera or microphone permission denied', name: 'AgoraService');
    }
    
    return granted;
  }
  
  /// 開始預覽
  Future<bool> startPreview() async {
    if (!_isInitialized || _engine == null) {
      developer.log('Agora not initialized', name: 'AgoraService');
      return false;
    }
    
    try {
      await _engine!.startPreview();
      developer.log('Preview started', name: 'AgoraService');
      return true;
    } catch (e) {
      developer.log('Start preview failed: $e', name: 'AgoraService');
      return false;
    }
  }
  
  /// 停止預覽
  Future<void> stopPreview() async {
    if (_engine != null) {
      await _engine!.stopPreview();
      developer.log('Preview stopped', name: 'AgoraService');
    }
  }
  
  /// 加入頻道開始推流
  Future<bool> joinChannel(String channelName, {String? token}) async {
    if (!_isInitialized || _engine == null) {
      developer.log('Agora not initialized', name: 'AgoraService');
      return false;
    }
    
    try {
      // 使用提供的 token 或配置中的 token
      final rtcToken = token ?? AppConfig.agoraToken;
      
      await _engine!.joinChannel(
        token: rtcToken.isEmpty ? '' : rtcToken,
        channelId: channelName,
        uid: 0, // 0 表示由 Agora 自動分配 UID
        options: const ChannelMediaOptions(
          channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
          clientRoleType: ClientRoleType.clientRoleBroadcaster,
          publishCameraTrack: true,
          publishMicrophoneTrack: true,
        ),
      );
      
      _isStreaming = true;
      developer.log('Joined channel: $channelName', name: 'AgoraService');
      return true;
    } catch (e) {
      developer.log('Join channel failed: $e', name: 'AgoraService');
      return false;
    }
  }
  
  /// 離開頻道停止推流
  Future<void> leaveChannel() async {
    if (_isStreaming && _engine != null) {
      await _engine!.leaveChannel();
      _isStreaming = false;
      developer.log('Left channel', name: 'AgoraService');
    }
  }
  
  /// 切換攝像頭
  Future<void> switchCamera() async {
    if (_engine != null) {
      await _engine!.switchCamera();
      _isFrontCamera = !_isFrontCamera;
      developer.log('Camera switched to ${_isFrontCamera ? "front" : "back"}', 
        name: 'AgoraService');
    }
  }
  
  /// 靜音/取消靜音
  Future<void> muteAudio(bool mute) async {
    if (_engine != null) {
      await _engine!.muteLocalAudioStream(mute);
      developer.log('Audio muted: $mute', name: 'AgoraService');
    }
  }
  
  /// 關閉/開啟攝像頭
  Future<void> muteVideo(bool mute) async {
    if (_engine != null) {
      await _engine!.muteLocalVideoStream(mute);
      developer.log('Video muted: $mute', name: 'AgoraService');
    }
  }
  
  /// 設置美顏（Agora 基礎美顏）
  Future<void> enableBeautify(bool enable) async {
    if (_engine == null) return;
    
    try {
      if (enable) {
        // 啟用美顏
        await _engine!.setBeautyEffectOptions(
          enabled: true,
          options: const BeautyOptions(
            lighteningContrastLevel: LighteningContrastLevel.lighteningContrastNormal,
            lighteningLevel: 0.7, // 美白程度 0.0-1.0
            smoothnessLevel: 0.5, // 磨皮程度 0.0-1.0
            rednessLevel: 0.1, // 紅潤度 0.0-1.0
            sharpnessLevel: 0.3, // 銳化程度 0.0-1.0
          ),
        );
      } else {
        // 關閉美顏
        await _engine!.setBeautyEffectOptions(
          enabled: false,
          options: const BeautyOptions(),
        );
      }
      
      developer.log('Beautify enabled: $enable', name: 'AgoraService');
    } catch (e) {
      developer.log('Enable beautify failed: $e', name: 'AgoraService');
    }
  }
  
  /// 推流到 CDN（可選，用於推到自定義 RTMP 地址）
  /// 注意：此功能需要 Agora 付費版本
  Future<bool> addPublishStreamUrl(String url, String streamId) async {
    if (_engine == null || !_isStreaming) {
      developer.log('Cannot add publish URL: not streaming', name: 'AgoraService');
      return false;
    }
    
    try {
      // Agora 的 RTMP 推流功能需要付費版本
      // 這裡僅作為預留接口
      developer.log('RTMP streaming requires Agora paid plan', name: 'AgoraService');
      return false;
    } catch (e) {
      developer.log('Add publish stream URL failed: $e', name: 'AgoraService');
      return false;
    }
  }
  
  /// 停止推流到 CDN
  Future<void> removePublishStreamUrl(String url) async {
    // 預留接口
    developer.log('RTMP streaming requires Agora paid plan', name: 'AgoraService');
  }
  
  /// 清理資源
  Future<void> dispose() async {
    await leaveChannel();
    await stopPreview();
    
    if (_engine != null) {
      await _engine!.release();
      _engine = null;
      _isInitialized = false;
      developer.log('Agora disposed', name: 'AgoraService');
    }
  }
}

