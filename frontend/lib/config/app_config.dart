import 'package:flutter_dotenv/flutter_dotenv.dart';

/// 應用配置
class AppConfig {
  // API 配置
  static String get apiBaseUrl => 
    dotenv.env['API_BASE_URL'] ?? 'http://localhost:3000/api';
  
  static String get wsBaseUrl => 
    dotenv.env['WS_BASE_URL'] ?? 'ws://localhost:3000';
  
  // SRS 配置
  static String get srsHttpUrl => 
    dotenv.env['SRS_HTTP_URL'] ?? 'http://localhost:8080';
  
  static String get rtmpBaseUrl => 
    dotenv.env['RTMP_BASE_URL'] ?? 'rtmp://localhost:1935/live';
  
  static String get hlsBaseUrl => 
    dotenv.env['HLS_BASE_URL'] ?? 'http://localhost:8080';
  
  static String get flvBaseUrl => 
    dotenv.env['FLV_BASE_URL'] ?? 'http://localhost:8080';
  
  // Agora 配置（從環境變數讀取）
  // 🔗 註冊: https://console.agora.io/
  // 📝 在 .env 文件中配置 AGORA_APP_ID
  static String get agoraAppId => 
    dotenv.env['AGORA_APP_ID'] ?? '';
  
  // Agora Token（生產環境使用，開發可留空）
  static String get agoraToken => 
    dotenv.env['AGORA_TOKEN'] ?? '';
  
  // 功能開關
  static const bool enableAppStreaming = true; // App 內推流
  static const bool enableOBSMode = true; // 同時支持 OBS 推流
  static const bool enableBeauty = true; // 基礎美顏功能
  
  // 調試模式
  static const bool debugMode = bool.fromEnvironment(
    'DEBUG_MODE',
    defaultValue: true,
  );
}

