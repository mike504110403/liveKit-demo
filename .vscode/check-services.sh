#!/bin/bash

echo "╔═══════════════════════════════════════════════════════════╗"
echo "║  🔍 檢查服務狀態                                            ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo ""

# 檢查後端
echo "📡 檢查後端服務 (http://localhost:3000)..."
if curl -s http://localhost:3000/api/rooms > /dev/null 2>&1; then
    echo "  ✅ 後端服務正常運行"
    ROOM_COUNT=$(curl -s http://localhost:3000/api/rooms | jq '. | length' 2>/dev/null || echo "無法解析")
    echo "  📊 當前直播間數量: $ROOM_COUNT"
else
    echo "  ❌ 後端服務未運行"
    echo "  💡 請執行: cd backend && go run main.go"
fi

echo ""

# 檢查 SRS
echo "🎥 檢查 SRS 服務 (http://localhost:8080)..."
if curl -s http://localhost:8080/api/v1/versions > /dev/null 2>&1; then
    echo "  ✅ SRS 服務正常運行"
else
    echo "  ❌ SRS 服務未運行"
    echo "  💡 請執行: docker-compose -f docker-compose-full.yml up -d"
fi

echo ""

# 檢查前端
echo "🌐 檢查前端服務 (http://localhost:8888)..."
if curl -s http://localhost:8888 > /dev/null 2>&1; then
    echo "  ✅ 前端服務正常運行"
else
    echo "  ❌ 前端服務未運行"
    echo "  💡 請在 VSCode 按 F5 啟動 Debug"
fi

echo ""
echo "╔═══════════════════════════════════════════════════════════╗"
echo "║  完成檢查                                                   ║"
echo "╚═══════════════════════════════════════════════════════════╝"
