package models

import "time"

// User 用戶模型
type User struct {
	ID       string `json:"id"`
	Nickname string `json:"nickname"`
	Token    string `json:"token"`
}

// Room 直播間模型
type Room struct {
	ID          string    `json:"id"`
	Title       string    `json:"title"`
	StreamKey   string    `json:"stream_key"`
	Status      string    `json:"status"` // idle, live
	HostID      string    `json:"host_id"`
	ViewerCount int       `json:"viewer_count"`
	CreatedAt   time.Time `json:"created_at"`
}

// ChatMessage 聊天消息模型
type ChatMessage struct {
	RoomID   string    `json:"room_id"`
	UserID   string    `json:"user_id"`
	Nickname string    `json:"nickname"`
	Message  string    `json:"message"`
	Time     time.Time `json:"time"`
}

// LoginRequest 登入請求
type LoginRequest struct {
	Nickname string `json:"nickname" binding:"required"`
}

// CreateRoomRequest 創建直播間請求
type CreateRoomRequest struct {
	Title string `json:"title" binding:"required"`
}

// SRSCallback SRS 回調結構
type SRSCallback struct {
	Action    string `json:"action"`
	ClientID  string `json:"client_id"`
	IP        string `json:"ip"`
	Vhost     string `json:"vhost"`
	App       string `json:"app"`
	Stream    string `json:"stream"`
	Param     string `json:"param"`
	ServerID  string `json:"server_id"`
	StreamURL string `json:"stream_url"`
	StreamID  string `json:"stream_id"`
}

// SRSResponse SRS 回調響應
type SRSResponse struct {
	Code int `json:"code"` // 0 表示成功
}

