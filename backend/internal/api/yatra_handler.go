package api

import (
	"encoding/json"
	"net/http"
	"strconv"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/manojmitharampawar/sahayatri/backend/internal/models"
	"github.com/manojmitharampawar/sahayatri/backend/internal/shapefile"
	"github.com/manojmitharampawar/sahayatri/backend/internal/store"
	"github.com/manojmitharampawar/sahayatri/backend/internal/ws"
)

type YatraHandler struct {
	yatraStore  *store.YatraStore
	hub         *ws.Hub
	shapeLoader *shapefile.Loader
}

func NewYatraHandler(ys *store.YatraStore, hub *ws.Hub, sl *shapefile.Loader) *YatraHandler {
	return &YatraHandler{yatraStore: ys, hub: hub, shapeLoader: sl}
}

func (h *YatraHandler) Create(c *gin.Context) {
	var req models.CreateYatraCardRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	userID := c.GetInt64("user_id")
	journeyDate, err := time.Parse("2006-01-02", req.JourneyDate)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid journey_date format, use YYYY-MM-DD"})
		return
	}

	card := &models.YatraCard{
		UserID:               userID,
		PNR:                  req.PNR,
		TrainNumber:          req.TrainNumber,
		BoardingStationID:    req.BoardingStationID,
		DestinationStationID: req.DestinationStationID,
		BerthInfo:            req.BerthInfo,
		JourneyDate:          journeyDate,
		Status:               "upcoming",
	}

	if err := h.yatraStore.Create(c.Request.Context(), card); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to create yatra card"})
		return
	}

	c.JSON(http.StatusCreated, card)
}

func (h *YatraHandler) List(c *gin.Context) {
	userID := c.GetInt64("user_id")
	cards, err := h.yatraStore.ListByUser(c.Request.Context(), userID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to list yatra cards"})
		return
	}
	c.JSON(http.StatusOK, cards)
}

func (h *YatraHandler) GetByID(c *gin.Context) {
	id, err := strconv.ParseInt(c.Param("id"), 10, 64)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid yatra ID"})
		return
	}

	card, err := h.yatraStore.GetByID(c.Request.Context(), id)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "yatra card not found"})
		return
	}

	c.JSON(http.StatusOK, card)
}

func (h *YatraHandler) UpdateLocation(c *gin.Context) {
	id, err := strconv.ParseInt(c.Param("id"), 10, 64)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid yatra ID"})
		return
	}

	var loc models.LocationUpdate
	if err := c.ShouldBindJSON(&loc); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	snappedLat, snappedLon := h.shapeLoader.SnapToTrack(loc.Lat, loc.Lon)

	breadcrumb := &models.Breadcrumb{
		YatraID:    id,
		Lat:        loc.Lat,
		Lon:        loc.Lon,
		SnappedLat: snappedLat,
		SnappedLon: snappedLon,
		Timestamp:  time.Now(),
	}

	if err := h.yatraStore.AddBreadcrumb(c.Request.Context(), breadcrumb); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to save breadcrumb"})
		return
	}

	msg, _ := json.Marshal(gin.H{
		"yatra_id":    id,
		"lat":         snappedLat,
		"lon":         snappedLon,
		"raw_lat":     loc.Lat,
		"raw_lon":     loc.Lon,
		"timestamp":   breadcrumb.Timestamp,
	})
	h.hub.Broadcast(id, msg)

	c.JSON(http.StatusOK, breadcrumb)
}
