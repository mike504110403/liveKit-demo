# 🎥 LiveKit Demo - 直播平台 MVP

基於 SRS 的直播平台最小可行產品，支持推流、播放、聊天功能。

## 📋 技術棧

### 後端
- **Go 1.23+** + Gin 框架
- 模塊化架構（models/store/handlers）
- 內存存儲（線程安全）
- HTTP REST API + WebSocket

### 前端
- **Flutter 3.x**
- 跨平台（iOS/Android/Web）
- HLS/FLV 播放
- WebSocket 實時聊天

### 直播核心
- **SRS 5.0**
- RTMP 推流
- HLS/FLV 拉流
- HTTP 回調

## 🚀 快速啟動

### ⚠️ 前置條件：配置 Agora SDK（可選）

**配置後可使用 App 內推流功能！**

📖 詳細步驟請查看：[AGORA_SETUP.md](AGORA_SETUP.md)

快速步驟：
1. 註冊 Agora 帳號：https://console.agora.io/ ✅ 台灣可直接註冊
2. 創建項目，獲取 App ID
3. 編輯 `frontend/lib/config/app_config.dart`，填入你的 App ID
4. 運行 `cd frontend && flutter pub get`

### 方式 1: Docker Compose（推薦）

```bash
# 啟動所有服務
docker-compose -f docker-compose-full.yml up -d

# 查看日誌
docker-compose -f docker-compose-full.yml logs -f

# 停止服務
docker-compose -f docker-compose-full.yml down
```

### 方式 2: 本地開發

#### 1. 啟動 SRS
```bash
cd srs
./start.sh
```

#### 2. 啟動後端
```bash
cd backend
go mod tidy
go run main.go
```

#### 3. 啟動 Flutter
```bash
cd frontend
flutter pub get
flutter run
```

## 📁 項目結構

```
livekit-demo/
├── backend/                    # Go 後端
│   ├── models/                # 數據模型
│   ├── store/                 # 存儲層
│   ├── handlers/              # 業務處理器
│   ├── main.go               # 主程序
│   └── Dockerfile
├── frontend/                  # Flutter 客戶端
│   ├── lib/
│   │   ├── config/           # 配置
│   │   ├── models/           # 數據模型
│   │   ├── services/         # API 服務
│   │   ├── screens/          # 頁面
│   │   ├── widgets/          # 組件
│   │   └── utils/            # 工具
│   └── pubspec.yaml
├── srs/                       # SRS 配置
│   ├── conf/srs.conf
│   └── start.sh
├── .cursor/rules/             # Cursor 開發規則
├── docker-compose-full.yml
├── ARCHITECTURE.md            # 架構文檔
└── README.md
```

## 🎯 核心功能

### 已實現
- ✅ 用戶登入
- ✅ 創建直播間
- ✅ OBS 推流
- ✅ HLS/FLV 播放
- ✅ WebSocket 聊天
- ✅ SRS 回調處理
- ✅ 在線人數統計

### 已實現（需配置）
- ✅ App 內推流（Agora SDK）
- ✅ 基礎美顏（磨皮、美白、銳化、紅潤）
- ✅ 推流控制（切換攝像頭、靜音、美顏開關）

### 待實現
- ⏳ 高級美顏（大眼、瘦臉、貼紙）
- ⏳ 數據持久化（PostgreSQL/Redis）
- ⏳ 用戶系統（註冊、密碼）

## 🔧 配置說明

### 後端配置
- 端口：3000
- 模塊：`livekit-demo`
- 存儲：內存（線程安全 Map）

### SRS 配置
- RTMP 端口：1935
- HTTP 端口：8080
- API 端口：1985
- 回調地址：http://localhost:3000/srs

### Flutter 配置

#### 1. Agora SDK 配置（可選）
修改 `frontend/lib/config/app_config.dart`：
```dart
// 填入你的 Agora App ID
static const String agoraAppId = 'your_app_id_here';  // ← 你的 App ID
```

#### 2. 網絡配置
```dart
// Android 模擬器
static const String apiBaseUrl = 'http://10.0.2.2:3000/api';

// iOS 模擬器
static const String apiBaseUrl = 'http://localhost:3000/api';

// 真機（使用電腦內網 IP）
static const String apiBaseUrl = 'http://192.168.1.100:3000/api';
```

## 📡 API 文檔

### 認證
```
POST /api/login
Body: {"nickname": "用戶名"}
Response: {"token": "xxx", "user_id": "xxx", "nickname": "xxx"}
```

### 直播間管理
```
POST /api/rooms              # 創建直播間
GET /api/rooms               # 獲取列表
GET /api/rooms/:id           # 獲取詳情
GET /api/rooms/:id/play_url  # 獲取播放地址
DELETE /api/rooms/:id        # 刪除直播間
```

### WebSocket 聊天
```
WS /chat/:room_id?token=xxx
```

### SRS 回調
```
POST /srs/on_publish         # 開始推流
POST /srs/on_unpublish       # 停止推流
```

## 🧪 測試流程

### 1. 啟動服務
```bash
# 檢查 SRS
curl http://localhost:1985/api/v1/versions

# 檢查後端
curl http://localhost:3000/health
```

### 2. 測試 App 內推流（推薦）
1. 打開 App（**必須用真機**）
2. 登錄
3. 創建直播間
4. 點擊「開始直播」按鈕
5. 允許攝像頭和麥克風權限
6. 開始推流，測試控制功能：
   - 切換前後攝像頭
   - 麥克風靜音/取消靜音
   - 攝像頭開關
   - 美顏開關

### 3. 測試 OBS 推流（備用）
1. 打開 App（Web/真機均可）
2. 創建直播間
3. 點擊「查看 OBS 推流地址」
4. 複製 RTMP 地址
5. OBS 設置：
   - 服務器：`rtmp://localhost:1935/live`
   - 串流金鑰：從 App 獲取的 `stream_key`
6. 開始串流

### 4. 觀看直播
1. 另一個設備打開 App
2. 在直播間列表點擊進入
3. 自動播放 HLS 流
4. 可以發送聊天消息

## 📚 文檔

- [AGORA_SETUP.md](AGORA_SETUP.md) - **Agora SDK 配置指南（推薦）**
- [ARCHITECTURE.md](ARCHITECTURE.md) - 系統架構說明
- [.cursor/rules/](.cursor/rules/) - 開發規範

## 🛠️ 開發工具

### 必需
- Go 1.23+
- Flutter 3.x
- Docker & Docker Compose

### 推薦
- VS Code + Flutter 插件
- Android Studio（Android 開發）
- Xcode（iOS 開發）
- OBS Studio（推流測試）

## 📝 開發規範

### 後端
- 使用模塊化架構
- 所有存儲操作必須線程安全
- 統一錯誤處理格式
- 完善的日誌輸出

### 前端
- 使用統一配置管理
- 封裝 API 和 WebSocket 服務
- 統一錯誤處理
- 組件化開發

### Git 提交
```
feat: 新功能
fix: 修復
refactor: 重構
docs: 文檔
style: 格式
test: 測試
```

## 🚨 常見問題

### 後端無法啟動
```bash
# 檢查端口占用
lsof -i :3000

# 重新整理依賴
cd backend && go mod tidy
```

### Flutter 無法連接
```bash
# Android 模擬器使用 10.0.2.2
# iOS 模擬器使用 localhost
# 真機使用電腦內網 IP
```

### SRS 推流失敗
```bash
# 檢查 SRS 日誌
docker-compose -f docker-compose-full.yml logs srs

# 檢查端口
telnet localhost 1935
```

## 📄 License

MIT

## 👥 貢獻

歡迎提交 Issue 和 Pull Request！
