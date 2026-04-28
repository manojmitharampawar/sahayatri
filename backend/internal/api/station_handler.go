package api

import (
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"
	"github.com/manojmitharampawar/sahayatri/backend/internal/store"
)

type StationHandler struct {
	stationStore *store.StationStore
}

func NewStationHandler(ss *store.StationStore) *StationHandler {
	return &StationHandler{stationStore: ss}
}

func (h *StationHandler) List(c *gin.Context) {
	stations, err := h.stationStore.List(c.Request.Context())
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to list stations"})
		return
	}
	c.JSON(http.StatusOK, stations)
}

func (h *StationHandler) Search(c *gin.Context) {
	q := c.Query("q")
	if q == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "query parameter 'q' is required"})
		return
	}

	stations, err := h.stationStore.Search(c.Request.Context(), q)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to search stations"})
		return
	}
	c.JSON(http.StatusOK, stations)
}

func (h *StationHandler) GetByID(c *gin.Context) {
	id, err := strconv.ParseInt(c.Param("id"), 10, 64)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid station ID"})
		return
	}

	station, err := h.stationStore.GetByID(c.Request.Context(), id)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "station not found"})
		return
	}
	c.JSON(http.StatusOK, station)
}
