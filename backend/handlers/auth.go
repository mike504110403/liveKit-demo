package handlers

import (
	"log"
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"srs-mobile-demo/models"
	"srs-mobile-demo/store"
)

type AuthHandler struct {
	store *store.MemoryStore
}

func NewAuthHandler(store *store.MemoryStore) *AuthHandler {
	return &AuthHandler{store: store}
}

// Login 登入
func (h *AuthHandler) Login(c *gin.Context) {
	var req models.LoginRequest
	
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "nickname is required"})
		return
	}
	
	user := &models.User{
		ID:       uuid.New().String(),
		Nickname: req.Nickname,
		Token:    uuid.New().String(),
	}
	
	h.store.SaveUser(user)
	
	log.Printf("[LOGIN] User: %s (ID: %s)", user.Nickname, user.ID)
	
	c.JSON(http.StatusOK, gin.H{
		"token":    user.Token,
		"user_id":  user.ID,
		"nickname": user.Nickname,
	})
}

