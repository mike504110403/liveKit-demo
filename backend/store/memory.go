package store

import (
	"log"
	"sync"

	"srs-mobile-demo/models"

	"github.com/gorilla/websocket"
)

// MemoryStore 內存存儲
type MemoryStore struct {
	users           map[string]*models.User      // token -> User
	rooms           map[string]*models.Room      // roomID -> Room
	streamKeyToRoom map[string]*models.Room      // streamKey -> Room
	chatClients     map[string][]*websocket.Conn // roomID -> connections
	mu              sync.RWMutex
}

// NewMemoryStore 創建內存存儲
func NewMemoryStore() *MemoryStore {
	return &MemoryStore{
		users:           make(map[string]*models.User),
		rooms:           make(map[string]*models.Room),
		streamKeyToRoom: make(map[string]*models.Room),
		chatClients:     make(map[string][]*websocket.Conn),
	}
}

// === User 操作 ===

func (s *MemoryStore) SaveUser(user *models.User) {
	s.mu.Lock()
	defer s.mu.Unlock()
	s.users[user.Token] = user
}

func (s *MemoryStore) GetUser(token string) (*models.User, bool) {
	s.mu.RLock()
	defer s.mu.RUnlock()
	user, exists := s.users[token]
	return user, exists
}

// === Room 操作 ===

func (s *MemoryStore) SaveRoom(room *models.Room) {
	s.mu.Lock()
	defer s.mu.Unlock()
	s.rooms[room.ID] = room
	s.streamKeyToRoom[room.StreamKey] = room
}

func (s *MemoryStore) GetRoom(roomID string) (*models.Room, bool) {
	s.mu.RLock()
	defer s.mu.RUnlock()
	room, exists := s.rooms[roomID]
	return room, exists
}

func (s *MemoryStore) GetRoomByStreamKey(streamKey string) (*models.Room, bool) {
	s.mu.RLock()
	defer s.mu.RUnlock()
	room, exists := s.streamKeyToRoom[streamKey]
	return room, exists
}

func (s *MemoryStore) GetAllRooms() []*models.Room {
	s.mu.RLock()
	defer s.mu.RUnlock()

	rooms := make([]*models.Room, 0, len(s.rooms))
	for _, room := range s.rooms {
		rooms = append(rooms, room)
	}
	return rooms
}

func (s *MemoryStore) UpdateRoomStatus(roomID string, status string) {
	s.mu.Lock()
	defer s.mu.Unlock()

	if room, exists := s.rooms[roomID]; exists {
		room.Status = status
	}
}

func (s *MemoryStore) DeleteRoom(roomID string) {
	s.mu.Lock()
	defer s.mu.Unlock()

	if room, exists := s.rooms[roomID]; exists {
		delete(s.streamKeyToRoom, room.StreamKey)
		delete(s.rooms, roomID)

		// 清理所有聊天連接
		if clients, exists := s.chatClients[roomID]; exists {
			// 關閉所有連接
			for _, conn := range clients {
				conn.Close()
			}
			delete(s.chatClients, roomID)
		}
	}
}

// GetUserRoom 獲取用戶的直播間
func (s *MemoryStore) GetUserRoom(hostID string) *models.Room {
	s.mu.RLock()
	defer s.mu.RUnlock()

	for _, room := range s.rooms {
		if room.HostID == hostID {
			return room
		}
	}
	return nil
}

// === Chat 操作 ===

func (s *MemoryStore) AddChatClient(roomID string, conn *websocket.Conn) {
	s.mu.Lock()
	defer s.mu.Unlock()
	s.chatClients[roomID] = append(s.chatClients[roomID], conn)
}

func (s *MemoryStore) RemoveChatClient(roomID string, conn *websocket.Conn) {
	s.mu.Lock()
	defer s.mu.Unlock()

	clients := s.chatClients[roomID]
	for i, c := range clients {
		if c == conn {
			s.chatClients[roomID] = append(clients[:i], clients[i+1:]...)
			break
		}
	}
}

func (s *MemoryStore) GetChatClients(roomID string) []*websocket.Conn {
	s.mu.RLock()
	defer s.mu.RUnlock()
	return s.chatClients[roomID]
}

func (s *MemoryStore) GetRoomViewerCount(roomID string) int {
	s.mu.RLock()
	defer s.mu.RUnlock()
	return len(s.chatClients[roomID])
}

// BroadcastToRoom 廣播消息到房間所有客戶端
func (s *MemoryStore) BroadcastToRoom(roomID string, message interface{}) {
	s.mu.RLock()
	clients := s.chatClients[roomID]
	s.mu.RUnlock()

	log.Printf("[BROADCAST] 房間 %s 有 %d 個連接客戶端", roomID, len(clients))

	successCount := 0
	for _, conn := range clients {
		err := conn.WriteJSON(message)
		if err != nil {
			log.Printf("[BROADCAST_ERROR] 發送失敗: %v", err)
		} else {
			successCount++
		}
	}

	log.Printf("[BROADCAST] 成功發送到 %d/%d 個客戶端", successCount, len(clients))
}
