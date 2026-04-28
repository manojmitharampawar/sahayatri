package api

import (
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/manojmitharampawar/sahayatri/backend/internal/shapefile"
)

type ShapefileHandler struct {
	loader *shapefile.Loader
}

func NewShapefileHandler(l *shapefile.Loader) *ShapefileHandler {
	return &ShapefileHandler{loader: l}
}

func (h *ShapefileHandler) GetTracks(c *gin.Context) {
	tracks := h.loader.GetTracks()
	c.JSON(http.StatusOK, tracks)
}
