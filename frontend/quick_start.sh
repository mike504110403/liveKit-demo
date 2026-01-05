#!/bin/bash

echo "🚀 快速啟動 Flutter (優化模式)"
echo ""

# 檢查是否有進程佔用端口
if lsof -Pi :8888 -sTCP:LISTEN -t >/dev/null 2>&1 ; then
    echo "⚠️  端口 8888 已被佔用，正在清理..."
    lsof -ti :8888 | xargs kill -9 2>/dev/null
    sleep 1
fi

# 啟動 Flutter（使用優化參數）
echo "▶️  啟動 Flutter..."
flutter run \
  -d chrome \
  --web-port 8888 \
  --dart-define=FLUTTER_WEB_USE_SKIA=false

# 注意：
# --dart-define=FLUTTER_WEB_USE_SKIA=false: 禁用 Skia（減少編譯時間）
# 使用 debug 模式以獲得最快的熱重載速度

