package api

import (
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"
	"github.com/gorilla/websocket"
	"github.com/manojmitharampawar/sahayatri/backend/internal/auth"
	"github.com/manojmitharampawar/sahayatri/backend/internal/models"
	"github.com/manojmitharampawar/sahayatri/backend/internal/store"
	"github.com/manojmitharampawar/sahayatri/backend/internal/ws"
)

var upgrader = websocket.Upgrader{
	ReadBufferSize:  1024,
	WriteBufferSize: 1024,
	CheckOrigin:     func(r *http.Request) bool { return true },
}

type FamilyHandler struct {
	familyStore *store.FamilyStore
	hub         *ws.Hub
	jwt         *auth.JWTService
}

func NewFamilyHandler(fs *store.FamilyStore, hub *ws.Hub, jwt *auth.JWTService) *FamilyHandler {
	return &FamilyHandler{familyStore: fs, hub: hub, jwt: jwt}
}

func (h *FamilyHandler) CreateGroup(c *gin.Context) {
	var req models.CreateFamilyGroupRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	userID := c.GetInt64("user_id")
	group := &models.FamilyGroup{
		Name:    req.Name,
		OwnerID: userID,
	}

	if err := h.familyStore.CreateGroup(c.Request.Context(), group); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to create family group"})
		return
	}

	// Add owner as admin member
	member := &models.FamilyMember{
		GroupID: group.ID,
		UserID:  userID,
		Role:    "admin",
	}
	h.familyStore.AddMember(c.Request.Context(), member)

	c.JSON(http.StatusCreated, group)
}

func (h *FamilyHandler) ListGroups(c *gin.Context) {
	userID := c.GetInt64("user_id")
	groups, err := h.familyStore.ListGroupsByUser(c.Request.Context(), userID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to list groups"})
		return
	}
	c.JSON(http.StatusOK, groups)
}

func (h *FamilyHandler) GetGroup(c *gin.Context) {
	id, err := strconv.ParseInt(c.Param("id"), 10, 64)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid group ID"})
		return
	}

	group, err := h.familyStore.GetGroup(c.Request.Context(), id)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "group not found"})
		return
	}

	members, err := h.familyStore.ListMembers(c.Request.Context(), id)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to list members"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"group": group, "members": members})
}

func (h *FamilyHandler) AddMember(c *gin.Context) {
	groupID, err := strconv.ParseInt(c.Param("id"), 10, 64)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid group ID"})
		return
	}

	var req models.AddFamilyMemberRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	member := &models.FamilyMember{
		GroupID: groupID,
		UserID:  req.UserID,
		Role:    req.Role,
	}

	if err := h.familyStore.AddMember(c.Request.Context(), member); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to add member"})
		return
	}

	c.JSON(http.StatusCreated, member)
}

func (h *FamilyHandler) RemoveMember(c *gin.Context) {
	groupID, err := strconv.ParseInt(c.Param("id"), 10, 64)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid group ID"})
		return
	}

	userID, err := strconv.ParseInt(c.Param("userId"), 10, 64)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid user ID"})
		return
	}

	if err := h.familyStore.RemoveMember(c.Request.Context(), groupID, userID); err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "member not found"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "member removed"})
}

func (h *FamilyHandler) LiveWebSocket(c *gin.Context) {
	yatraID, err := strconv.ParseInt(c.Param("yatraId"), 10, 64)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid yatra ID"})
		return
	}

	userID := c.GetInt64("user_id")

	conn, err := upgrader.Upgrade(c.Writer, c.Request, nil)
	if err != nil {
		return
	}

	client := &ws.Client{
		Hub:     h.hub,
		Conn:    conn,
		Send:    make(chan []byte, 256),
		YatraID: yatraID,
		UserID:  userID,
	}

	h.hub.Register(yatraID, client)

	go client.WritePump()
	go client.ReadPump()
}
