package api

import (
	"github.com/gin-gonic/gin"
	"github.com/manojmitharampawar/sahayatri/backend/internal/auth"
	"github.com/manojmitharampawar/sahayatri/backend/internal/cache"
	"github.com/manojmitharampawar/sahayatri/backend/internal/shapefile"
	"github.com/manojmitharampawar/sahayatri/backend/internal/store"
	"github.com/manojmitharampawar/sahayatri/backend/internal/ws"
)

func NewRouter(
	jwtSvc *auth.JWTService,
	userStore *store.UserStore,
	yatraStore *store.YatraStore,
	stationStore *store.StationStore,
	familyStore *store.FamilyStore,
	cacheStore *cache.Cache,
	hub *ws.Hub,
	shapeLoader *shapefile.Loader,
) *gin.Engine {
	r := gin.Default()

	r.GET("/health", func(c *gin.Context) {
		c.JSON(200, gin.H{"status": "ok"})
	})

	v1 := r.Group("/api/v1")

	// Auth routes (public)
	authHandler := NewAuthHandler(jwtSvc, userStore)
	v1.POST("/auth/register", authHandler.Register)
	v1.POST("/auth/login", authHandler.Login)
	v1.POST("/auth/refresh", authHandler.Refresh)

	// Protected routes
	protected := v1.Group("")
	protected.Use(jwtSvc.AuthMiddleware())

	// Station routes
	stationHandler := NewStationHandler(stationStore)
	protected.GET("/stations", stationHandler.List)
	protected.GET("/stations/search", stationHandler.Search)
	protected.GET("/stations/:id", stationHandler.GetByID)

	// Train status routes
	trainHandler := NewTrainHandler(cacheStore)
	protected.GET("/trains/:number/status", trainHandler.GetStatus)

	// PNR routes
	pnrHandler := NewPNRHandler(cacheStore)
	protected.GET("/pnr/:pnr/status", pnrHandler.GetStatus)

	// Yatra routes
	yatraHandler := NewYatraHandler(yatraStore, hub, shapeLoader)
	protected.POST("/yatra", yatraHandler.Create)
	protected.GET("/yatra", yatraHandler.List)
	protected.GET("/yatra/:id", yatraHandler.GetByID)
	protected.PUT("/yatra/:id/location", yatraHandler.UpdateLocation)

	// Family routes
	familyHandler := NewFamilyHandler(familyStore, hub, jwtSvc)
	protected.POST("/family", familyHandler.CreateGroup)
	protected.GET("/family", familyHandler.ListGroups)
	protected.GET("/family/:id", familyHandler.GetGroup)
	protected.POST("/family/:id/members", familyHandler.AddMember)
	protected.DELETE("/family/:id/members/:userId", familyHandler.RemoveMember)

	// WebSocket route (public — auth via query param token)
	v1.GET("/family/live/:yatraId", familyHandler.LiveWebSocket)

	// Shapefile routes
	shapeHandler := NewShapefileHandler(shapeLoader)
	protected.GET("/shapefiles/tracks", shapeHandler.GetTracks)

	return r
}
