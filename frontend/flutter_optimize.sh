#!/bin/bash

echo "╔═══════════════════════════════════════════════════╗"
echo "║  🚀 Flutter 編譯速度優化腳本                       ║"
echo "╚═══════════════════════════════════════════════════╝"
echo ""

# 1. 清理舊的編譯產物
echo "🧹 清理舊的編譯產物..."
flutter clean
rm -rf .dart_tool/
rm -rf build/
rm -rf ios/Pods/
rm -rf ios/.symlinks/
rm -rf android/.gradle/
rm -rf android/app/build/

# 2. 更新依賴（移除不需要的包）
echo ""
echo "📦 更新依賴..."
flutter pub get

# 3. 預編譯 Dart 代碼
echo ""
echo "⚡ 預編譯 Dart 代碼..."
flutter pub run build_runner clean 2>/dev/null || true

# 4. 啟用 Flutter 快取
echo ""
echo "💾 配置 Flutter 快取..."
flutter config --enable-web
flutter config --no-analytics

# 5. 清理 Xcode DerivedData（Mac）
if [ -d ~/Library/Developer/Xcode/DerivedData ]; then
    echo ""
    echo "🧹 清理 Xcode DerivedData..."
    rm -rf ~/Library/Developer/Xcode/DerivedData/*
fi

# 6. 清理 Gradle 快取（Android）
if [ -d ~/.gradle/caches ]; then
    echo ""
    echo "🧹 清理 Gradle 快取..."
    rm -rf ~/.gradle/caches/
fi

echo ""
echo "╔═══════════════════════════════════════════════════╗"
echo "║  ✅ 優化完成！                                     ║"
echo "╚═══════════════════════════════════════════════════╝"
echo ""
echo "📋 下次啟動建議："
echo "   flutter run -d chrome --web-port 8888 --release"
echo ""
echo "或使用 debug 模式（更快的熱重載）："
echo "   flutter run -d chrome --web-port 8888"
echo ""

