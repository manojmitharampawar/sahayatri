package scheduler

import (
	"context"
	"log"
	"time"

	"github.com/manojmitharampawar/sahayatri/backend/internal/cache"
	"github.com/manojmitharampawar/sahayatri/backend/internal/store"
)

type PNRStatusJob struct {
	yatraStore *store.YatraStore
	cache      *cache.Cache
}

func NewPNRStatusJob(ys *store.YatraStore, c *cache.Cache) *PNRStatusJob {
	return &PNRStatusJob{
		yatraStore: ys,
		cache:      c,
	}
}

func (j *PNRStatusJob) Run() {
	ctx := context.Background()

	cards, err := j.yatraStore.ListActive(ctx)
	if err != nil {
		log.Printf("PNRStatusJob: failed to list active yatras: %v", err)
		return
	}

	updated := 0
	for _, card := range cards {
		if card.Status == "confirmed" {
			continue
		}

		status := j.fetchPNRStatus(card.PNR)
		if status == "" {
			continue
		}

		if err := j.cache.SetPNRStatus(ctx, card.PNR, status, 15*time.Minute); err != nil {
			log.Printf("PNRStatusJob: failed to cache PNR %s: %v", card.PNR, err)
			continue
		}

		if err := j.yatraStore.UpdateStatus(ctx, card.ID, status); err != nil {
			log.Printf("PNRStatusJob: failed to update yatra %d: %v", card.ID, err)
			continue
		}

		updated++
	}

	log.Printf("PNRStatusJob: updated %d PNR statuses", updated)
}

func (j *PNRStatusJob) fetchPNRStatus(pnr string) string {
	// TODO: integrate with PNR status API
	_ = pnr
	return ""
}
