package scheduler

import (
	"context"
	"log"
	"time"

	"github.com/manojmitharampawar/sahayatri/backend/internal/cache"
	"github.com/manojmitharampawar/sahayatri/backend/internal/models"
	"github.com/manojmitharampawar/sahayatri/backend/internal/store"
)

type TrainStatusJob struct {
	yatraStore *store.YatraStore
	cache      *cache.Cache
}

func NewTrainStatusJob(ys *store.YatraStore, c *cache.Cache) *TrainStatusJob {
	return &TrainStatusJob{
		yatraStore: ys,
		cache:      c,
	}
}

func (j *TrainStatusJob) Run() {
	ctx := context.Background()

	cards, err := j.yatraStore.ListActive(ctx)
	if err != nil {
		log.Printf("TrainStatusJob: failed to list active yatras: %v", err)
		return
	}

	seen := make(map[string]bool)
	for _, card := range cards {
		if seen[card.TrainNumber] {
			continue
		}
		seen[card.TrainNumber] = true

		status := j.fetchTrainStatus(card.TrainNumber)
		if status == nil {
			continue
		}

		if err := j.cache.SetTrainStatus(ctx, status, 2*time.Minute); err != nil {
			log.Printf("TrainStatusJob: failed to cache train %s: %v", card.TrainNumber, err)
		}
	}

	log.Printf("TrainStatusJob: refreshed %d trains", len(seen))
}

func (j *TrainStatusJob) fetchTrainStatus(trainNumber string) *models.TrainStatus {
	// TODO: integrate with NTES/RailYatri API for live train data
	return &models.TrainStatus{
		TrainNumber:   trainNumber,
		CurrentLat:    0,
		CurrentLon:    0,
		DelayMinutes:  0,
		LastFetchedAt: time.Now(),
	}
}
