package api

import (
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/manojmitharampawar/sahayatri/backend/internal/cache"
)

type PNRHandler struct {
	cache *cache.Cache
}

func NewPNRHandler(c *cache.Cache) *PNRHandler {
	return &PNRHandler{cache: c}
}

func (h *PNRHandler) GetStatus(c *gin.Context) {
	pnr := c.Param("pnr")

	status, err := h.cache.GetPNRStatus(c.Request.Context(), pnr)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to fetch PNR status"})
		return
	}

	if status == "" {
		c.JSON(http.StatusNotFound, gin.H{"error": "PNR status not available"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"pnr": pnr, "status": status})
}
