package handlers

import (
	"encoding/json"
	"log"
	"net/http"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/gorilla/websocket"
	"srs-mobile-demo/models"
	"srs-mobile-demo/store"
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
	
	if token == "" {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "token required"})
		return
	}
	
	user, exists := h.store.GetUser(token)
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "invalid token"})
		return
	}
	
	room, exists := h.store.GetRoom(roomID)
	if !exists {
		c.JSON(http.StatusNotFound, gin.H{"error": "room not found"})
		return
	}
	
	// 升級為 WebSocket
	conn, err := h.upgrader.Upgrade(c.Writer, c.Request, nil)
	if err != nil {
		log.Printf("[WS_ERROR] Upgrade failed: %v", err)
		return
	}
	defer conn.Close()
	
	// 添加到聊天室
	h.store.AddChatClient(roomID, conn)
	defer h.store.RemoveChatClient(roomID, conn)
	
	log.Printf("[WS_CONNECT] User: %s joined room: %s", user.Nickname, room.Title)
	
	// 發送歡迎消息
	welcomeMsg := models.ChatMessage{
		RoomID:   roomID,
		UserID:   "system",
		Nickname: "系統",
		Message:  user.Nickname + " 加入了直播間",
		Time:     time.Now(),
	}
	h.broadcastMessage(roomID, welcomeMsg)
	
	// 讀取消息
	for {
		var msg struct {
			Message string `json:"message"`
		}
		
		err := conn.ReadJSON(&msg)
		if err != nil {
			log.Printf("[WS_DISCONNECT] User: %s left room: %s", user.Nickname, room.Title)
			break
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

