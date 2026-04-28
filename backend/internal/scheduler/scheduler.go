package scheduler

import (
	"log"

	"github.com/robfig/cron/v3"
)

type Scheduler struct {
	cron             *cron.Cron
	trainStatusJob   *TrainStatusJob
	pnrStatusJob     *PNRStatusJob
}

func New(tsj *TrainStatusJob, psj *PNRStatusJob) *Scheduler {
	return &Scheduler{
		cron:           cron.New(),
		trainStatusJob: tsj,
		pnrStatusJob:   psj,
	}
}

func (s *Scheduler) Start() {
	// Poll train status every 2 minutes
	if _, err := s.cron.AddFunc("*/2 * * * *", s.trainStatusJob.Run); err != nil {
		log.Printf("Failed to schedule train status job: %v", err)
	}

	// Poll PNR status every 15 minutes
	if _, err := s.cron.AddFunc("*/15 * * * *", s.pnrStatusJob.Run); err != nil {
		log.Printf("Failed to schedule PNR status job: %v", err)
	}

	s.cron.Start()
	log.Println("Scheduler started")
}

func (s *Scheduler) Stop() {
	s.cron.Stop()
	log.Println("Scheduler stopped")
}
