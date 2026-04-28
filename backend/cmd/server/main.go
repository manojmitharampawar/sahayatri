package main

import (
	"context"
	"log"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/manojmitharampawar/sahayatri/backend/config"
	"github.com/manojmitharampawar/sahayatri/backend/internal/api"
	"github.com/manojmitharampawar/sahayatri/backend/internal/auth"
	"github.com/manojmitharampawar/sahayatri/backend/internal/cache"
	"github.com/manojmitharampawar/sahayatri/backend/internal/scheduler"
	"github.com/manojmitharampawar/sahayatri/backend/internal/shapefile"
	"github.com/manojmitharampawar/sahayatri/backend/internal/store"
	"github.com/manojmitharampawar/sahayatri/backend/internal/ws"
)

func main() {
	cfg := config.Load()

	// Database
	db, err := store.NewDB(cfg.DB)
	if err != nil {
		log.Fatalf("Failed to connect to database: %v", err)
	}
	defer db.Close()

	// Stores
	userStore := store.NewUserStore(db)
	yatraStore := store.NewYatraStore(db)
	stationStore := store.NewStationStore(db)
	familyStore := store.NewFamilyStore(db)

	// Cache
	redisCache := cache.New(cfg.Redis)
	defer redisCache.Close()

	// Auth
	jwtSvc := auth.NewJWTService(cfg.JWT)

	// WebSocket hub
	hub := ws.NewHub()

	// Shapefile loader
	shapeLoader := shapefile.NewLoader("data/railway_tracks.geojson")
	if err := shapeLoader.Load(); err != nil {
		log.Printf("Warning: failed to load shapefile: %v", err)
	}

	// Scheduler
	trainStatusJob := scheduler.NewTrainStatusJob(yatraStore, redisCache)
	pnrStatusJob := scheduler.NewPNRStatusJob(yatraStore, redisCache)
	sched := scheduler.New(trainStatusJob, pnrStatusJob)
	sched.Start()
	defer sched.Stop()

	// Router
	router := api.NewRouter(jwtSvc, userStore, yatraStore, stationStore, familyStore, redisCache, hub, shapeLoader)

	// Server
	srv := &http.Server{
		Addr:         ":" + cfg.Server.Port,
		Handler:      router,
		ReadTimeout:  cfg.Server.ReadTimeout,
		WriteTimeout: cfg.Server.WriteTimeout,
	}

	// Graceful shutdown
	go func() {
		log.Printf("Server starting on :%s", cfg.Server.Port)
		if err := srv.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			log.Fatalf("Server error: %v", err)
		}
	}()

	quit := make(chan os.Signal, 1)
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
	<-quit

	log.Println("Shutting down server...")
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	if err := srv.Shutdown(ctx); err != nil {
		log.Fatalf("Server forced to shutdown: %v", err)
	}

	log.Println("Server stopped")
}
