package main

import (
	"log"
	"os"

	"srs-mobile-demo/handlers"
	"srs-mobile-demo/store"

	"github.com/gin-gonic/gin"
)

func main() {
	// 創建內存存儲
	memStore := store.NewMemoryStore()

	// 創建處理器
	authHandler := handlers.NewAuthHandler(memStore)
	roomHandler := handlers.NewRoomHandler(memStore)
	srsHandler := handlers.NewSRSHandler(memStore)
	chatHandler := handlers.NewChatHandler(memStore)

	// 設置 Gin
	r := gin.Default()

	// CORS 中間件
	r.Use(corsMiddleware())

	// 健康檢查
	r.GET("/health", func(c *gin.Context) {
		c.JSON(200, gin.H{"status": "ok"})
	})

	// API 路由
	api := r.Group("/api")
	{
		// 認證
		api.POST("/login", authHandler.Login)

		// 直播間
		api.POST("/rooms", roomHandler.CreateRoom)
		api.GET("/rooms", roomHandler.GetRooms)
		api.GET("/rooms/my", roomHandler.GetMyRoom) // 獲取我的直播間
		api.GET("/rooms/:id", roomHandler.GetRoom)
		api.GET("/rooms/:id/play_url", roomHandler.GetPlayURL)
		api.PATCH("/rooms/:id/status", roomHandler.UpdateRoomStatus)
		api.DELETE("/rooms/:id", roomHandler.DeleteRoom)
	}

	// SRS 回調
	r.POST("/srs/on_publish", srsHandler.OnPublish)
	r.POST("/srs/on_unpublish", srsHandler.OnUnpublish)

	// WebSocket 聊天
	r.GET("/chat/:room_id", chatHandler.HandleWebSocket)

	// 啟動服務器
	port := os.Getenv("PORT")
	if port == "" {
		port = "3000"
	}

	log.Printf("🚀 Server starting on port %s", port)
	log.Printf("📡 API: http://localhost:%s/api", port)
	log.Printf("💬 WebSocket: ws://localhost:%s/chat", port)
	log.Printf("🎥 SRS Callback: http://localhost:%s/srs", port)

	if err := r.Run(":" + port); err != nil {
		log.Fatalf("Failed to start server: %v", err)
	}
}

// corsMiddleware CORS 中間件
func corsMiddleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		c.Writer.Header().Set("Access-Control-Allow-Origin", "*")
		c.Writer.Header().Set("Access-Control-Allow-Credentials", "true")
		c.Writer.Header().Set("Access-Control-Allow-Headers", "Content-Type, Content-Length, Accept-Encoding, X-CSRF-Token, Authorization, accept, origin, Cache-Control, X-Requested-With")
		c.Writer.Header().Set("Access-Control-Allow-Methods", "POST, OPTIONS, GET, PUT, DELETE, PATCH")

		if c.Request.Method == "OPTIONS" {
			c.AbortWithStatus(204)
			return
		}

		c.Next()
	}
}
