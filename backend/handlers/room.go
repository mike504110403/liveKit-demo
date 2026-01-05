package handlers

import (
	"fmt"
	"log"
	"net/http"
	"time"

	"srs-mobile-demo/models"
	"srs-mobile-demo/store"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

type RoomHandler struct {
	store *store.MemoryStore
}

func NewRoomHandler(store *store.MemoryStore) *RoomHandler {
	return &RoomHandler{store: store}
}

// CreateRoom 創建直播間
func (h *RoomHandler) CreateRoom(c *gin.Context) {
	token := c.GetHeader("Authorization")
	if token == "" {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "unauthorized"})
		return
	}
	
	user, exists := h.store.GetUser(token)
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "invalid token"})
		return
	}
	
	// 檢查用戶是否已有直播間
	existingRoom := h.store.GetUserRoom(user.ID)
	if existingRoom != nil {
		c.JSON(http.StatusConflict, gin.H{
			"error": "你已經有一個直播間了",
			"room_id": existingRoom.ID,
		})
		return
	}
	
	var req models.CreateRoomRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "title is required"})
		return
	}
	
	room := &models.Room{
		ID:          uuid.New().String(),
		Title:       req.Title,
		StreamKey:   fmt.Sprintf("stream_%s", uuid.New().String()[:8]),
		Status:      "idle",
		HostID:      user.ID,
		ViewerCount: 0,
		CreatedAt:   time.Now(),
	}
	
	h.store.SaveRoom(room)
	
	log.Printf("[CREATE_ROOM] Room: %s (ID: %s, Host: %s)", room.Title, room.ID, user.Nickname)
	
	c.JSON(http.StatusOK, gin.H{
		"room_id":    room.ID,
		"title":      room.Title,
		"stream_key": room.StreamKey,
		"rtmp_url":   fmt.Sprintf("rtmp://localhost:1935/live/%s", room.StreamKey),
		"status":     room.Status,
	})
}

// GetRooms 獲取直播間列表
func (h *RoomHandler) GetRooms(c *gin.Context) {
	rooms := h.store.GetAllRooms()
	
	// 更新觀看人數
	for _, room := range rooms {
		room.ViewerCount = h.store.GetRoomViewerCount(room.ID)
	}
	
	c.JSON(http.StatusOK, rooms)
}

// GetMyRoom 獲取我的直播間
func (h *RoomHandler) GetMyRoom(c *gin.Context) {
	token := c.GetHeader("Authorization")
	if token == "" {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "unauthorized"})
		return
	}
	
	user, exists := h.store.GetUser(token)
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "invalid token"})
		return
	}
	
	room := h.store.GetUserRoom(user.ID)
	if room == nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "no room found"})
		return
	}
	
	room.ViewerCount = h.store.GetRoomViewerCount(room.ID)
	
	c.JSON(http.StatusOK, room)
}

// GetRoom 獲取直播間詳情
func (h *RoomHandler) GetRoom(c *gin.Context) {
	roomID := c.Param("id")
	
	room, exists := h.store.GetRoom(roomID)
	if !exists {
		c.JSON(http.StatusNotFound, gin.H{"error": "room not found"})
		return
	}
	
	room.ViewerCount = h.store.GetRoomViewerCount(roomID)
	
	c.JSON(http.StatusOK, room)
}

// GetPlayURL 獲取播放地址
func (h *RoomHandler) GetPlayURL(c *gin.Context) {
	roomID := c.Param("id")
	
	room, exists := h.store.GetRoom(roomID)
	if !exists {
		c.JSON(http.StatusNotFound, gin.H{"error": "room not found"})
		return
	}
	
	// 加上時間戳防止緩存
	timestamp := time.Now().UnixMilli()
	
	c.JSON(http.StatusOK, gin.H{
		"hls": fmt.Sprintf("http://localhost:8080/live/%s.m3u8?t=%d", room.StreamKey, timestamp),
		"flv": fmt.Sprintf("http://localhost:8080/live/%s.flv?t=%d", room.StreamKey, timestamp),
	})
}

// UpdateRoomStatus 更新直播間狀態（開始/停止直播）
func (h *RoomHandler) UpdateRoomStatus(c *gin.Context) {
	roomID := c.Param("id")
	token := c.GetHeader("Authorization")
	
	if token == "" {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "unauthorized"})
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
	
	// 驗證是否為房主
	if room.HostID != user.ID {
		c.JSON(http.StatusForbidden, gin.H{"error": "not room owner"})
		return
	}
	
	var req struct {
		Status string `json:"status" binding:"required"` // idle, live
	}
	
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "status is required"})
		return
	}
	
	// 驗證狀態值
	if req.Status != "idle" && req.Status != "live" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid status, must be 'idle' or 'live'"})
		return
	}
	
	oldStatus := room.Status
	h.store.UpdateRoomStatus(roomID, req.Status)
	
	// 如果從 idle 變為 live（開始直播），通知所有觀眾
	if oldStatus == "idle" && req.Status == "live" {
		h.store.BroadcastToRoom(roomID, map[string]interface{}{
			"type":    "stream_started",
			"room_id": roomID,
			"message": "主播開始直播了",
		})
		log.Printf("[STREAM_STARTED] Room: %s (ID: %s), Broadcasting to viewers", room.Title, room.ID)
	}
	
	// 如果從 live 變為 idle（停止直播），通知所有觀眾
	if oldStatus == "live" && req.Status == "idle" {
		h.store.BroadcastToRoom(roomID, map[string]interface{}{
			"type":    "stream_stopped",
			"room_id": roomID,
			"message": "主播已停止直播",
		})
		log.Printf("[STREAM_STOPPED] Room: %s (ID: %s), Broadcasting to viewers", room.Title, room.ID)
	}
	
	log.Printf("[UPDATE_ROOM_STATUS] Room: %s (ID: %s, Status: %s -> %s)", room.Title, room.ID, oldStatus, req.Status)
	
	c.JSON(http.StatusOK, gin.H{
		"room_id": room.ID,
		"status":  req.Status,
		"message": "room status updated",
	})
}

// DeleteRoom 刪除直播間（關閉直播間）
func (h *RoomHandler) DeleteRoom(c *gin.Context) {
	roomID := c.Param("id")
	token := c.GetHeader("Authorization")
	
	if token == "" {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "unauthorized"})
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
	
	if room.HostID != user.ID {
		c.JSON(http.StatusForbidden, gin.H{"error": "not room owner"})
		return
	}
	
	// 廣播通知所有觀眾直播間已關閉
	h.store.BroadcastToRoom(roomID, map[string]interface{}{
		"type": "room_closed",
		"room_id": roomID,
		"message": "直播間已關閉",
	})
	
	// 清理所有房間相關數據
	h.store.DeleteRoom(roomID)
	
	log.Printf("[DELETE_ROOM] Room: %s (ID: %s, Host: %s)", room.Title, room.ID, user.Nickname)
	
	c.JSON(http.StatusOK, gin.H{"message": "room deleted"})
}

