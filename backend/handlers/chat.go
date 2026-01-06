package handlers

import (
	"encoding/json"
	"log"
	"net/http"
	"time"

	"srs-mobile-demo/models"
	"srs-mobile-demo/store"

	"github.com/gin-gonic/gin"
	"github.com/gorilla/websocket"
)

type ChatHandler struct {
	store    *store.MemoryStore
	upgrader websocket.Upgrader
}

func NewChatHandler(store *store.MemoryStore) *ChatHandler {
	return &ChatHandler{
		store: store,
		upgrader: websocket.Upgrader{
			CheckOrigin: func(r *http.Request) bool {
				return true // 生產環境需要限制
			},
		},
	}
}

// HandleWebSocket 處理 WebSocket 連接
func (h *ChatHandler) HandleWebSocket(c *gin.Context) {
	roomID := c.Param("room_id")
	token := c.Query("token")

	log.Printf("[WS] 收到連接請求 - Room: %s, Token: %s", roomID, token)

	if token == "" {
		log.Printf("[WS_ERROR] Token 為空")
		c.JSON(http.StatusUnauthorized, gin.H{"error": "token required"})
		return
	}

	user, exists := h.store.GetUser(token)
	if !exists {
		log.Printf("[WS_ERROR] 無效的 Token: %s", token)
		c.JSON(http.StatusUnauthorized, gin.H{"error": "invalid token"})
		return
	}

	room, exists := h.store.GetRoom(roomID)
	if !exists {
		log.Printf("[WS_ERROR] 房間不存在: %s", roomID)
		c.JSON(http.StatusNotFound, gin.H{"error": "room not found"})
		return
	}

	// 升級為 WebSocket
	conn, err := h.upgrader.Upgrade(c.Writer, c.Request, nil)
	if err != nil {
		log.Printf("[WS_ERROR] 升級失敗: %v", err)
		return
	}
	defer conn.Close()

	// 添加到聊天室
	h.store.AddChatClient(roomID, conn)
	defer h.store.RemoveChatClient(roomID, conn)

	log.Printf("[WS_CONNECT] ✅ 用戶 %s (ID: %s) 加入房間 %s (ID: %s)", user.Nickname, user.ID, room.Title, roomID)

	// 發送歡迎消息
	welcomeMsg := models.ChatMessage{
		RoomID:   roomID,
		UserID:   "system",
		Nickname: "系統",
		Message:  user.Nickname + " 加入了直播間",
		Time:     time.Now(),
	}
	h.broadcastMessage(roomID, welcomeMsg)

	// 設置 Pong 處理器（心跳包）
	conn.SetPongHandler(func(string) error {
		log.Printf("[WS_PONG] 收到來自 %s 的心跳回應", user.Nickname)
		conn.SetReadDeadline(time.Now().Add(60 * time.Second))
		return nil
	})

	// 啟動心跳 goroutine
	pingTicker := time.NewTicker(30 * time.Second)
	defer pingTicker.Stop()

	// 啟動讀取 goroutine
	done := make(chan struct{})
	go func() {
		defer close(done)
		for {
			var msg struct {
				Type    string `json:"type"`
				Message string `json:"message"`
			}

			err := conn.ReadJSON(&msg)
			if err != nil {
				log.Printf("[WS_DISCONNECT] 用戶 %s 離開房間 %s: %v", user.Nickname, room.Title, err)
				return
			}

			// 過濾心跳包
			if msg.Type == "ping" {
				log.Printf("[WS_HEARTBEAT] 收到來自 %s 的心跳", user.Nickname)
				continue
			}

			// 過濾空消息
			if msg.Message == "" {
				log.Printf("[WS_SKIP] 跳過空消息 - 用戶: %s", user.Nickname)
				continue
			}

			chatMsg := models.ChatMessage{
				RoomID:   roomID,
				UserID:   user.ID,
				Nickname: user.Nickname,
				Message:  msg.Message,
				Time:     time.Now(),
			}

			log.Printf("[CHAT] %s: %s", user.Nickname, msg.Message)
			h.broadcastMessage(roomID, chatMsg)
		}
	}()

	// 主 goroutine 負責心跳
	for {
		select {
		case <-pingTicker.C:
			log.Printf("[WS_PING] 發送心跳到 %s", user.Nickname)
			if err := conn.WriteMessage(websocket.PingMessage, nil); err != nil {
				log.Printf("[WS_ERROR] 心跳發送失敗: %v", err)
				return
			}
		case <-done:
			log.Printf("[WS_DONE] 連接已關閉 - %s", user.Nickname)
			return
		}
	}
}

// broadcastMessage 廣播消息到聊天室
func (h *ChatHandler) broadcastMessage(roomID string, msg models.ChatMessage) {
	clients := h.store.GetChatClients(roomID)
	data, _ := json.Marshal(msg)

	for _, client := range clients {
		err := client.WriteMessage(websocket.TextMessage, data)
		if err != nil {
			log.Printf("[WS_ERROR] Send message failed: %v", err)
		}
	}
}
