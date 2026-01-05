#!/bin/bash

# 啟動 SRS 服務器
echo "🚀 啟動 SRS 直播服務器..."

docker run -d --name srs \
  -p 1935:1935 \
  -p 8080:8080 \
  -p 1985:1985 \
  -v $(pwd)/conf/srs.conf:/usr/local/srs/conf/srs.conf \
  ossrs/srs:5

echo "✅ SRS 已啟動"
echo ""
echo "📺 推流地址: rtmp://localhost:1935/live/{stream_key}"
echo "🎬 HLS 拉流: http://localhost:8080/live/{stream_key}.m3u8"
echo "📡 FLV 拉流: http://localhost:8080/live/{stream_key}.flv"
echo "🔧 API 地址: http://localhost:1985/api/v1/summaries"
echo ""
echo "查看日誌: docker logs -f srs"
echo "停止服務: docker stop srs && docker rm srs"

