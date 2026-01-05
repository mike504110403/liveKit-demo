# Agora SDK 設置指南

## 🎯 為什麼選擇 Agora？

- ✅ **全球可用**（新加坡公司，台灣可直接註冊）
- ✅ **免費額度**：每月 10,000 分鐘
- ✅ **支持美顏和濾鏡**
- ✅ **文檔完善**，有繁體中文支援
- ✅ **Flutter SDK 成熟**，API 友好

## 📝 註冊步驟

### 1. 前往 Agora 控制台
🔗 https://console.agora.io/

### 2. 註冊帳號
- **Email 註冊**：推薦，簡單快速
- **Google 登入**：更方便
- **不需要**中國手機號碼 ✅

### 3. 創建項目

#### 步驟：
1. 登入後，點擊「創建項目」
2. 輸入項目名稱：`SRS Mobile Demo`
3. 選擇「安全模式」：
   - **開發階段**：選擇「APP ID」（無需 Token）
   - **生產環境**：選擇「APP ID + Token」（更安全）
4. 點擊「提交」

### 4. 獲取 App ID

創建完成後，在項目列表中：
1. 找到你的項目
2. 點擊「查看」或眼睛圖標
3. 複製 **App ID**（格式：32位字符串）

範例：`a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6`

## ⚙️ 配置專案

### 1. 編輯配置文件

打開：`frontend/lib/config/app_config.dart`

```dart
// Agora 配置
static const String agoraAppId = String.fromEnvironment(
  'AGORA_APP_ID',
  defaultValue: '', // ⚠️ 在這裡填入你的 App ID
);
```

替換為：

```dart
// Agora 配置
static const String agoraAppId = String.fromEnvironment(
  'AGORA_APP_ID',
  defaultValue: 'a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6', // 你的 App ID
);
```

### 2. 安裝依賴

```bash
cd frontend
flutter pub get
```

## 🚀 功能說明

### 已實現功能

- ✅ **視頻推流**：720p @ 30fps
- ✅ **音頻推流**：標準音質
- ✅ **攝像頭切換**：前後攝像頭
- ✅ **靜音控制**：麥克風開關
- ✅ **視頻控制**：攝像頭開關
- ✅ **基礎美顏**：磨皮、美白、銳化
- ✅ **實時預覽**：推流前預覽
- ✅ **WebSocket 聊天**：實時互動

### 美顏參數（可調整）

在 `agora_service.dart` 中：

```dart
BeautyOptions(
  lighteningLevel: 0.7,    // 美白：0.0-1.0
  smoothnessLevel: 0.5,    // 磨皮：0.0-1.0
  rednessLevel: 0.1,       // 紅潤：0.0-1.0
  sharpnessLevel: 0.3,     // 銳化：0.0-1.0
)
```

## 📱 使用方式

### 1. 啟動 App

```bash
cd frontend
flutter run
```

### 2. 測試流程

1. **登入**：輸入暱稱
2. **創建直播間**：點擊右下角 ➕ 按鈕
3. **授權權限**：允許相機和麥克風
4. **開始直播**：點擊「開始直播」按鈕

### 3. 控制面板

推流時底部控制按鈕：
- 🔄 **切換攝像頭**
- 🎤 **靜音/取消靜音**
- 📹 **攝像頭開關**
- 😊 **美顏開關**（需啟用）

## 🔧 高級配置

### 推流到自定義 RTMP

Agora 支援推流到自定義 RTMP 地址（如您的 SRS 服務器）：

```dart
// 在 agora_service.dart 中
await _agoraService.addPublishStreamUrl(
  'rtmp://your-server.com/live/stream_key',
  'stream_key',
);
```

**注意**：需要 Agora 付費版才支援 RTMP 推流轉碼。

### 視頻參數調整

編輯 `agora_service.dart`：

```dart
VideoEncoderConfiguration(
  dimensions: VideoDimensions(width: 1280, height: 720), // 解析度
  frameRate: 30,           // 幀率
  bitrate: 2000,           // 碼率 (kbps)
  orientationMode: OrientationMode.orientationModeFixedPortrait,
)
```

預設配置：
- **720p (1280x720)**：適合大多數場景
- **30 FPS**：流暢度好
- **2000 kbps**：畫質清晰

可選配置：
- **1080p (1920x1080)** - 需要更高帶寬
- **480p (640x480)** - 低帶寬環境

## 📊 免費額度說明

### Agora 免費額度

- **每月**：10,000 分鐘
- **適用**：視頻通話 + 直播
- **計算方式**：
  - 主播推流：按實際時長計算
  - 觀眾拉流：按實際時長計算
  - 範例：1小時直播（1主播 + 10觀眾）= 11 × 60 = 660 分鐘

### 超出額度後

- 按量計費
- 詳情：https://www.agora.io/cn/pricing/

### 節省用量技巧

1. **測試時**：及時停止推流
2. **開發時**：避免長時間推流
3. **生產時**：監控用量

## ❓ 常見問題

### Q1: App ID 填寫錯誤怎麼辦？
A: 重新編輯 `app_config.dart`，重新運行 App

### Q2: 提示權限被拒絕
A: 
- iOS: 設定 → App → 權限 → 允許相機和麥克風
- Android: 同上

### Q3: 推流失敗
A: 檢查：
1. App ID 是否正確
2. 網絡連接是否正常
3. 防火牆是否阻擋

### Q4: 看不到視頻預覽
A: 
1. 確認權限已授予
2. 檢查 `_isInitialized` 狀態
3. 查看控制台日誌

### Q5: 美顏不生效
A: 
1. 確認 `enableBeauty` 為 `true`
2. 檢查 Agora 版本是否支援
3. 某些低端設備可能不支援

### Q6: 相比 ZEGO 有什麼優勢？
A:
- ✅ 台灣可直接註冊（無需中國手機號）
- ✅ 文檔和支援更好
- ✅ 社群活躍
- ✅ 價格透明

## 🔗 相關資源

- **官方文檔**：https://docs.agora.io/cn/
- **Flutter SDK**：https://docs.agora.io/cn/flutter/
- **控制台**：https://console.agora.io/
- **社群論壇**：https://rtcdeveloper.agora.io/

## 🆚 與 OBS 推流對比

| 功能 | Agora App 內推流 | OBS 推流 |
|------|-----------------|----------|
| 易用性 | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ |
| 手機直播 | ✅ 完美支援 | ❌ 需要電腦 |
| 美顏濾鏡 | ✅ 內建 | ⚠️ 需插件 |
| 成本 | 免費額度 | 完全免費 |
| 延遲 | 低（< 3秒） | 低（< 3秒） |
| 畫質控制 | SDK 控制 | 手動設置 |

**建議**：
- **測試**：先用 OBS（免費、無限制）
- **生產**：用 Agora（更好的用戶體驗）

## ✅ 檢查清單

配置完成後，確認：
- [ ] 已註冊 Agora 帳號
- [ ] 已創建項目並獲取 App ID
- [ ] 已在 `app_config.dart` 填入 App ID
- [ ] 已運行 `flutter pub get`
- [ ] App 可以正常啟動
- [ ] 可以看到視頻預覽
- [ ] 可以開始推流

全部完成？🎉 **開始測試吧！**

---

**需要幫助？** 查看日誌或聯繫支援團隊。

