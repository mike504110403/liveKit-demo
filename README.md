# 🎥 SRS Mobile Demo - 直播平台

基於 SRS 的跨平台直播應用，支持 OBS 推流、實時播放、聊天互動等功能。

## ✨ 特色功能

### 已實現 ✅
- ✅ **跨平台支持**: Web、iOS、Android 一套代碼
- ✅ **OBS 推流**: RTMP 推流到 SRS 服務器
- ✅ **自適應播放**: Web 使用 HLS，Mobile 使用 HTTP-FLV（低延遲）
- ✅ **實時聊天**: WebSocket 實時通訊，支持聊天和系統通知
- ✅ **狀態同步**: 直播開始/停止實時通知所有觀眾
- ✅ **心跳機制**: WebSocket 長連接保活（前端 25s，後端 30s）
- ✅ **在線人數**: 實時顯示觀看人數
- ✅ **房間管理**: 創建、進入、離開直播間

### 技術亮點 🌟
- **播放器重建機制**: 使用 UniqueKey 確保再次開播時播放器完全重建
- **防緩存策略**: URL 時間戳 + HTTP headers + 關閉 GOP 緩存
- **消息過濾**: 自動過濾心跳包和空消息，確保聊天同步正確
- **詳細日誌**: 完整的連接、廣播、心跳日誌，方便調試
- **線程安全**: 後端使用 RWMutex 保證併發安全

---

## 📋 技術棧

### 前端
- **Flutter 3.x** (Web + iOS + Android)
- **video_player** - Web HLS 播放
- **fijkplayer** - Mobile HTTP-FLV 播放（低延遲）
- **web_socket_channel** - WebSocket 通訊

### 後端
- **Go 1.23+** + Gin 框架
- **Gorilla WebSocket** - WebSocket 服務器
- 模塊化架構（models/store/handlers）
- 內存存儲（線程安全）

### 流媒體
- **SRS 5.0** (Simple Realtime Server)
- RTMP 推流（端口 1935）
- HLS/HTTP-FLV 拉流（端口 8080）
- HTTP 回調機制

---

## 🚀 快速開始

### 前置條件
- Docker & Docker Compose（推薦）
- 或者：Go 1.23+、Flutter 3.x

### 方式 1: Docker Compose（一鍵啟動）✨

```bash
# 克隆項目
git clone <your-repo-url>
cd srs-mobile-demo

# 啟動所有服務（SRS + 後端 API）
docker-compose -f docker-compose-full.yml up -d

# 查看日誌
docker-compose -f docker-compose-full.yml logs -f

# 檢查服務狀態
docker ps
```

### 方式 2: 本地開發

#### 1. 啟動 SRS
```bash
cd srs
./start.sh

# 檢查 SRS 狀態
curl http://localhost:1985/api/v1/versions
```

#### 2. 啟動後端
```bash
cd backend
go mod tidy
go run main.go

# 或者後台運行並輸出日誌
go run main.go > /tmp/backend.log 2>&1 &

# 查看日誌
tail -f /tmp/backend.log
```

#### 3. 啟動 Flutter 前端
```bash
cd frontend
flutter pub get

# Web 開發
flutter run -d chrome

# iOS/Android 開發
flutter run
```

---

## 📁 項目結構

```
srs-mobile-demo/
├── backend/                    # Go 後端
│   ├── models/                # 數據模型
│   │   └── models.go          # User, Room, ChatMessage
│   ├── store/                 # 存儲層
│   │   └── memory.go          # 內存存儲 + WebSocket 廣播
│   ├── handlers/              # 業務處理器
│   │   ├── auth.go           # 用戶認證
│   │   ├── room.go           # 房間管理
│   │   ├── chat.go           # WebSocket 聊天（含心跳）
│   │   └── srs.go            # SRS 回調處理
│   ├── main.go               # 主程序
│   ├── go.mod
│   └── Dockerfile
│
├── frontend/                  # Flutter 客戶端
│   ├── lib/
│   │   ├── config/           # 配置
│   │   │   └── app_config.dart
│   │   ├── models/           # 數據模型
│   │   │   ├── user.dart
│   │   │   ├── room.dart
│   │   │   └── chat_message.dart
│   │   ├── services/         # API 服務
│   │   │   ├── api_service.dart     # REST API
│   │   │   └── websocket_service.dart  # WebSocket（含心跳）
│   │   ├── screens/          # 頁面
│   │   │   ├── login_screen.dart    # 登錄
│   │   │   ├── home_screen.dart     # 房間列表
│   │   │   ├── player_screen.dart   # 觀看直播
│   │   │   └── stream_screen.dart   # 主播推流
│   │   ├── widgets/          # 組件
│   │   │   ├── adaptive_video_player.dart  # 自適應播放器
│   │   │   ├── chat_widget.dart
│   │   │   └── loading_widget.dart
│   │   └── main.dart
│   └── pubspec.yaml
│
├── srs/                       # SRS 配置
│   ├── conf/
│   │   └── srs.conf          # SRS 主配置（關閉 GOP 緩存、HLS 配置）
│   └── start.sh
│
├── docker-compose-full.yml    # Docker Compose 配置
├── .cursorrules              # 開發規範（重要！）
└── README.md
```

---

## 🎯 核心功能說明

### 1. 直播流程

```
┌─────────┐   RTMP   ┌─────────┐  HLS/FLV  ┌─────────┐
│   OBS   │ ───────> │   SRS   │ ────────> │ 觀眾端  │
└─────────┘          └─────────┘           └─────────┘
                          │
                          │ HTTP Callback
                          ▼
                    ┌──────────┐
                    │ 後端 API  │ ← WebSocket 通知
                    └──────────┘
```

### 2. 狀態同步機制

**開始直播流程**:
1. 主播在 OBS 開始推流
2. SRS 收到 `on_publish` 回調
3. 後端更新房間狀態為 `live`
4. 後端通過 WebSocket 廣播 `stream_started` 給房間內所有觀眾
5. 觀眾收到通知，生成新的 `UniqueKey`
6. Flutter 檢測到 key 變化，完全重建 `AdaptiveVideoPlayer`
7. 播放器初始化並開始拉流

**停止直播流程**:
1. 主播在 OBS 停止推流
2. SRS 收到 `on_unpublish` 回調
3. 後端更新房間狀態為 `idle`
4. 後端通過 WebSocket 廣播 `stream_stopped`
5. 觀眾收到通知，清理播放器資源

### 3. WebSocket 心跳機制

**前端（25 秒）**:
```dart
// 每 25 秒發送心跳
_pingTimer = Timer.periodic(Duration(seconds: 25), (timer) {
  _channel!.sink.add(jsonEncode({'type': 'ping'}));
});
```

**後端（30 秒）**:
```go
// 每 30 秒發送 WebSocket Ping frame
pingTicker := time.NewTicker(30 * time.Second)
for {
  select {
  case <-pingTicker.C:
    conn.WriteMessage(websocket.PingMessage, nil)
  }
}

// 過濾心跳包，不廣播到聊天
if msg.Type == "ping" {
  continue
}
```

### 4. 播放器重建機制

**問題**: 停止直播後再次開播，播放器可能不會重新初始化

**解決方案**: 使用 `UniqueKey` 強制 Flutter 重建 Widget

```dart
// State 中定義
Key _playerKey = UniqueKey();

// 收到開始直播通知時
_streamStartedSubscription = _wsService.onStreamStarted.listen((message) {
  setState(() {
    _roomStatus = 'live';
    _playerKey = UniqueKey();  // 🔑 關鍵！強制重建
  });
  _initPlayer();
});

// 使用 key
AdaptiveVideoPlayer(
  key: _playerKey,  // 每次開播都是新的 key
  hlsUrl: _hlsUrl!,
  flvUrl: _flvUrl!,
)
```

---

## 🔧 配置說明

### 後端配置
- **端口**: 3000
- **API 路徑**: `/api/*`
- **WebSocket**: `/chat/:room_id?token=xxx`
- **SRS 回調**: `/srs/on_publish`, `/srs/on_unpublish`
- **日誌**: `/tmp/backend.log`（本地開發）

### SRS 配置（重要）

**文件**: `srs/conf/srs.conf`

```nginx
vhost __defaultVhost__ {
    min_latency     on;
    gop_cache       off;              # 🔑 關閉 GOP 緩存，避免舊畫面
    queue_length    10;
    tcp_nodelay     on;
    
    hls {
        enabled         on;
        hls_fragment    4;            # 4秒切片（配合OBS關鍵幀）
        hls_window      60;           # 保留15個切片（60秒窗口）
        hls_wait_keyframe on;
    }
    
    http_remux {
        enabled     on;               # HTTP-FLV 支援
        fast_cache  2;
    }
    
    http_hooks {
        enabled         on;
        on_publish      http://api:3000/srs/on_publish;
        on_unpublish    http://api:3000/srs/on_unpublish;
    }
}
```

**關鍵配置解釋**:
- `gop_cache off`: 關閉 GOP 緩存，防止顯示舊畫面
- `hls_fragment 4`: 4 秒切片，配合 OBS 關鍵幀間隔
- `hls_window 60`: 保留 60 秒的切片（15 個 × 4 秒）
- `http_remux`: 啟用 HTTP-FLV，提供低延遲播放

### Flutter 配置

**文件**: `frontend/lib/config/app_config.dart`

```dart
class AppConfig {
  // API 配置
  static String get apiBaseUrl => 'http://localhost:3000/api';
  static String get wsBaseUrl => 'ws://localhost:3000';
  
  // SRS 配置
  static String get srsHttpUrl => 'http://localhost:8080';
  static String get rtmpBaseUrl => 'rtmp://localhost:1935/live';
  static String get hlsBaseUrl => 'http://localhost:8080';
  static String get flvBaseUrl => 'http://localhost:8080';
}
```

**不同環境配置**:
```dart
// Android 模擬器
static String get apiBaseUrl => 'http://10.0.2.2:3000/api';

// iOS 模擬器
static String get apiBaseUrl => 'http://localhost:3000/api';

// 真機（使用電腦內網 IP）
static String get apiBaseUrl => 'http://192.168.1.100:3000/api';
```

---

## 📡 API 文檔

### 認證
```http
POST /api/login
Content-Type: application/json

{
  "nickname": "用戶名"
}

Response:
{
  "id": "user_id",
  "nickname": "用戶名",
  "token": "auth_token"
}
```

### 房間管理
```http
# 創建直播間
POST /api/rooms
Headers: Authorization: Bearer {token}
Body: {"title": "房間名稱"}

# 獲取房間列表
GET /api/rooms

# 獲取單個房間
GET /api/rooms/:id

# 獲取播放地址
GET /api/rooms/:id/play_url
Response: {
  "hls": "http://localhost:8080/live/xxx.m3u8?t=1234567890",
  "flv": "http://localhost:8080/live/xxx.flv?t=1234567890"
}

# 刪除房間
DELETE /api/rooms/:id
```

### WebSocket 聊天
```
連接: ws://localhost:3000/chat/:room_id?token=xxx

發送消息:
{
  "message": "Hello"
}

接收消息:
{
  "room_id": "room_id",
  "user_id": "user_id",
  "nickname": "nickname",
  "message": "Hello",
  "time": "2024-01-01T00:00:00Z"
}

系統通知:
{
  "type": "stream_started",
  "message": "直播已開始"
}

{
  "type": "stream_stopped",
  "message": "直播已停止"
}
```

---

## 🧪 測試流程

### 1. 檢查服務狀態

```bash
# 檢查 SRS
curl http://localhost:1985/api/v1/versions

# 檢查後端
curl http://localhost:3000/health

# 查看後端日誌
tail -f /tmp/backend.log
```

### 2. 測試 OBS 推流

1. 打開 Flutter App（Web 或真機）
2. 登錄（輸入暱稱）
3. 點擊「創建直播間」
4. 點擊「查看推流資訊」，複製 RTMP 地址和串流金鑰
5. 打開 OBS Studio：
   - 設定 → 串流
   - 服務：自訂
   - 伺服器：`rtmp://localhost:1935/live`
   - 串流金鑰：從 App 複製的 `stream_key`
6. OBS 開始串流

### 3. 測試觀看直播

1. 另一個設備/瀏覽器打開 App
2. 登錄
3. 在直播間列表看到「直播中」的紅色標籤
4. 點擊進入房間
5. 自動開始播放（Web 使用 HLS，Mobile 使用 FLV）

### 4. 測試聊天功能

1. 主播端發送消息
2. 觀眾端應該立即收到
3. 觀眾端發送消息
4. 主播端應該立即收到
5. 兩邊的消息列表應該完全一致

### 5. 測試停止→再開播（重要）

1. 觀眾進入直播間
2. 主播 OBS 停止串流
3. 觀眾看到「直播已停止」
4. 主播 OBS 再次開始串流
5. 觀眾自動收到通知並開始播放（**關鍵測試**）

---

## 🐛 故障排查

### 問題 1: 畫面不動或顯示舊畫面

**症狀**: 播放器初始化了，但畫面定格在第一幀

**原因**:
- HLS 切片緩存
- m3u8 播放列表緩存
- GOP 緩存未關閉

**解決步驟**:
1. 檢查 `srs/conf/srs.conf` 確認 `gop_cache off`
2. 重啟 SRS: `docker compose -f docker-compose-full.yml restart srs`
3. 檢查 URL 是否有時間戳參數 `?t=xxx`
4. 清除瀏覽器緩存（Ctrl+Shift+R 強制刷新）

### 問題 2: 再次開播時播放器不工作

**症狀**: 停止直播後再開播，觀眾收到通知但看不到畫面

**原因**: 播放器實例未重建，Flutter 認為是同一個 Widget

**解決**: 檢查代碼是否使用 `UniqueKey`
```dart
// ❌ 錯誤：沒有 key
AdaptiveVideoPlayer(
  hlsUrl: _hlsUrl!,
  flvUrl: _flvUrl!,
)

// ✅ 正確：使用 UniqueKey
AdaptiveVideoPlayer(
  key: _playerKey,  // 每次開播生成新的 key
  hlsUrl: _hlsUrl!,
  flvUrl: _flvUrl!,
)
```

### 問題 3: 聊天消息不同步或有空消息

**症狀**: 兩邊的聊天內容不一樣，或者出現空消息（`viewer:`, `streamer:`）

**原因**: 心跳包被當作聊天消息廣播了

**解決**: 檢查後端 `chat.go` 是否過濾心跳包
```go
// 必須過濾
if msg.Type == "ping" {
  continue  // 不廣播心跳包
}
```

**驗證**:
```bash
# 查看後端日誌
tail -f /tmp/backend.log | grep -E "\[WS_HEARTBEAT\]|\[CHAT\]"

# 應該看到心跳被過濾
# [WS_HEARTBEAT] 收到來自 viewer 的心跳
# [CHAT] viewer: 你好  ← 正常消息
```

### 問題 4: WebSocket 連接失敗或意外斷開

**症狀**: 前端 Console 顯示 WebSocket 錯誤

**檢查清單**:
1. 後端是否在運行？`curl http://localhost:3000/health`
2. 前端連接 URL 是否正確？`ws://localhost:3000/chat/:room_id?token=xxx`
3. Token 是否有效？
4. 查看後端日誌：`tail -f /tmp/backend.log | grep "\[WS"`

**心跳日誌檢查**:
```bash
# 應該看到定期的心跳日誌
[WS_PING] 發送心跳到 viewer
[WS_PONG] 收到來自 viewer 的心跳回應
[WS_HEARTBEAT] 收到來自 viewer 的心跳
```

### 問題 5: 觀眾沒收到開播通知

**症狀**: 主播開始推流，但觀眾沒有自動開始播放

**檢查步驟**:
1. 查看後端日誌是否有廣播記錄：
```bash
tail -f /tmp/backend.log | grep -E "\[STREAM_STARTED\]|\[BROADCAST\]"

# 應該看到：
# [STREAM_STARTED] Room: xxx, Broadcasting to viewers
# [BROADCAST] 房間 xxx 有 2 個連接客戶端
# [BROADCAST] 成功發送到 2/2 個客戶端
```

2. 檢查前端是否監聽了 `onStreamStarted`：
```dart
_streamStartedSubscription = _wsService.onStreamStarted.listen((message) {
  // 應該有這個監聽
});
```

3. 檢查前端 Console 是否有日誌：
```
📩 [WebSocket] 收到原始數據: {"type":"stream_started","message":"直播已開始"}
▶️  [WebSocket] 收到開始直播通知: 直播已開始
```

---

## 🔍 日誌說明

### 後端日誌位置
- Docker: `docker logs api -f`
- 本地: `/tmp/backend.log`

### 日誌標籤說明
```
[WS_CONNECT]      - WebSocket 連接成功
[WS_DISCONNECT]   - WebSocket 斷開連接
[WS_PING]         - 發送 Ping 心跳
[WS_PONG]         - 收到 Pong 回應
[WS_HEARTBEAT]    - 收到前端心跳
[WS_SKIP]         - 跳過空消息
[CHAT]            - 聊天消息
[BROADCAST]       - 廣播消息
[STREAM_STARTED]  - 直播開始
[STREAM_STOPPED]  - 直播停止
[SRS_PUBLISH]     - SRS 推流回調
[SRS_UNPUBLISH]   - SRS 停止推流回調
```

### 常用日誌過濾命令
```bash
# 查看 WebSocket 連接
tail -f /tmp/backend.log | grep "\[WS_CONNECT\]"

# 查看聊天消息
tail -f /tmp/backend.log | grep "\[CHAT\]"

# 查看廣播
tail -f /tmp/backend.log | grep "\[BROADCAST\]"

# 查看直播狀態變化
tail -f /tmp/backend.log | grep -E "\[STREAM_STARTED\]|\[STREAM_STOPPED\]"

# 查看心跳
tail -f /tmp/backend.log | grep -E "\[WS_PING\]|\[WS_PONG\]|\[WS_HEARTBEAT\]"

# 查看 SRS 回調
tail -f /tmp/backend.log | grep -E "\[SRS_"
```

---

## 📚 相關文檔

- [.cursorrules](./.cursorrules) - **開發規範（必讀）**
- [SRS 官方文檔](https://ossrs.net/lts/zh-cn/docs/v5/doc/introduction)
- [Flutter video_player](https://pub.dev/packages/video_player)
- [fijkplayer](https://pub.dev/packages/fijkplayer)
- [Gorilla WebSocket](https://github.com/gorilla/websocket)

---

## 🛠️ 開發工具

### 必需
- **Go 1.23+** - 後端開發
- **Flutter 3.x** - 前端開發
- **Docker & Docker Compose** - 服務編排
- **OBS Studio** - 推流測試

### 推薦
- **VS Code** + Flutter 插件
- **Cursor AI** - 配合 .cursorrules 使用
- **Postman** - API 測試
- **Chrome DevTools** - 前端調試

---

## 📝 開發規範

### 重要原則（來自 .cursorrules）

1. ✅ **保持播放器簡單**: 使用標準的 video_player 和 fijkplayer
2. ✅ **狀態同步至關重要**: 開始/停止直播必須通過 WebSocket 通知
3. ✅ **使用 UniqueKey 強制重建**: 確保播放器在再次開播時完全重建
4. ✅ **WebSocket 心跳機制**: 前端 25 秒，後端 30 秒 Ping
5. ✅ **過濾心跳包**: 後端必須過濾 `type: ping` 和空消息
6. ✅ **詳細日誌**: 所有關鍵操作都要有日誌

### 後端規範
```go
// ✅ 正確：詳細的日誌
log.Printf("[WS_CONNECT] ✅ 用戶 %s 加入房間 %s", user.Nickname, room.Title)

// ✅ 正確：過濾心跳包
if msg.Type == "ping" {
  log.Printf("[WS_HEARTBEAT] 收到來自 %s 的心跳", user.Nickname)
  continue  // 不廣播
}

// ✅ 正確：廣播前檢查連接數
log.Printf("[BROADCAST] 房間 %s 有 %d 個連接客戶端", roomID, len(clients))
```

### 前端規範
```dart
// ✅ 正確：使用 UniqueKey 強制重建
setState(() {
  _playerKey = UniqueKey();
});

// ✅ 正確：詳細的日誌
print('🔌 [WebSocket] 嘗試連接: $url');
print('✅ [WebSocket] 連接成功');

// ✅ 正確：錯誤處理
_channel!.stream.listen(
  (data) { /* ... */ },
  onError: (error) {
    print('❌ [WebSocket] 連接錯誤: $error');
  },
  cancelOnError: false,
);
```

---

## 🚨 常見錯誤

### 1. 忘記使用 UniqueKey
```dart
// ❌ 錯誤
AdaptiveVideoPlayer(hlsUrl: url, flvUrl: url)

// ✅ 正確
AdaptiveVideoPlayer(key: _playerKey, hlsUrl: url, flvUrl: url)
```

### 2. 沒有過濾心跳包
```go
// ❌ 錯誤：直接廣播所有消息
h.broadcastMessage(roomID, chatMsg)

// ✅ 正確：先過濾
if msg.Type == "ping" {
  continue
}
h.broadcastMessage(roomID, chatMsg)
```

### 3. 沒有重新獲取房間狀態
```dart
// ❌ 錯誤：直接使用傳入的狀態
_roomStatus = widget.room.status;

// ✅ 正確：重新獲取最新狀態
_fetchRoomStatus().then((_) {
  if (_roomStatus == 'live') {
    _initPlayer();
  }
});
```

---

## 📄 License

MIT

## 👥 貢獻

歡迎提交 Issue 和 Pull Request！

開發前請閱讀：
- [.cursorrules](./.cursorrules) - 完整的開發規範
- 確保遵循日誌、心跳、狀態同步等關鍵原則

---

## 📞 聯繫方式

如有問題，請提交 Issue 或查看：
- [開發規範](./.cursorrules)
- [故障排查](#-故障排查)
- [常見錯誤](#-常見錯誤)
