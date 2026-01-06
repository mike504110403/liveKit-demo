package handlers

import (
	"log"
	"net/http"

	"github.com/gin-gonic/gin"
	"srs-mobile-demo/models"
	"srs-mobile-demo/store"
)

type SRSHandler struct {
	store *store.MemoryStore
}

func NewSRSHandler(store *store.MemoryStore) *SRSHandler {
	return &SRSHandler{store: store}
}

// OnPublish SRS 推流回調
func (h *SRSHandler) OnPublish(c *gin.Context) {
	var callback models.SRSCallback
	
	if err := c.ShouldBindJSON(&callback); err != nil {
		log.Printf("[SRS_CALLBACK] Parse error: %v", err)
		c.JSON(http.StatusOK, models.SRSResponse{Code: 0}) // 仍然返回成功
		return
	}
	
	log.Printf("[SRS_PUBLISH] Stream: %s, IP: %s", callback.Stream, callback.IP)
	
	// 更新直播間狀態為 live
	room, exists := h.store.GetRoomByStreamKey(callback.Stream)
	if exists {
		oldStatus := room.Status
		h.store.UpdateRoomStatus(room.ID, "live")
		log.Printf("[ROOM_LIVE] Room: %s (ID: %s)", room.Title, room.ID)
		
		// 如果從 idle 變為 live，通知所有觀眾開始拉流
		if oldStatus == "idle" {
			h.store.BroadcastToRoom(room.ID, map[string]interface{}{
				"type":    "stream_started",
				"message": "直播已開始",
			})
			log.Printf("[STREAM_STARTED] Room: %s (ID: %s), Broadcasting to viewers", room.Title, room.ID)
		}
	}
	
	// 必須返回 code: 0
	c.JSON(http.StatusOK, models.SRSResponse{Code: 0})
}

// OnUnpublish SRS 停止推流回調
func (h *SRSHandler) OnUnpublish(c *gin.Context) {
	var callback models.SRSCallback
	
	if err := c.ShouldBindJSON(&callback); err != nil {
		log.Printf("[SRS_CALLBACK] Parse error: %v", err)
		c.JSON(http.StatusOK, models.SRSResponse{Code: 0})
		return
	}
	
	log.Printf("[SRS_UNPUBLISH] Stream: %s", callback.Stream)
	
	// 更新直播間狀態為 idle
	room, exists := h.store.GetRoomByStreamKey(callback.Stream)
	if exists {
		oldStatus := room.Status
		h.store.UpdateRoomStatus(room.ID, "idle")
		log.Printf("[ROOM_IDLE] Room: %s (ID: %s)", room.Title, room.ID)
		
		// 如果從 live 變為 idle，通知所有觀眾停止拉流
		if oldStatus == "live" {
			h.store.BroadcastToRoom(room.ID, map[string]interface{}{
				"type":    "stream_stopped",
				"message": "直播已停止",
			})
			log.Printf("[STREAM_STOPPED] Room: %s (ID: %s), Broadcasting to viewers", room.Title, room.ID)
		}
	}
	
	c.JSON(http.StatusOK, models.SRSResponse{Code: 0})
}

