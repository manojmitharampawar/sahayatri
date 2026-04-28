package api

import (
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/manojmitharampawar/sahayatri/backend/internal/cache"
)

type TrainHandler struct {
	cache *cache.Cache
}

func NewTrainHandler(c *cache.Cache) *TrainHandler {
	return &TrainHandler{cache: c}
}

func (h *TrainHandler) GetStatus(c *gin.Context) {
	number := c.Param("number")

	status, err := h.cache.GetTrainStatus(c.Request.Context(), number)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to fetch train status"})
		return
	}

	if status == nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "train status not available"})
		return
	}

	c.JSON(http.StatusOK, status)
}
