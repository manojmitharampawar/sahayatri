package models

import "time"

type TrainStatus struct {
	TrainNumber  string    `json:"train_number" db:"train_number"`
	CurrentLat   float64   `json:"current_lat" db:"current_lat"`
	CurrentLon   float64   `json:"current_lon" db:"current_lon"`
	DelayMinutes int       `json:"delay_minutes" db:"delay_minutes"`
	LastFetchedAt time.Time `json:"last_fetched_at" db:"last_fetched_at"`
}

type Breadcrumb struct {
	ID         int64     `json:"id" db:"id"`
	YatraID    int64     `json:"yatra_id" db:"yatra_id"`
	Lat        float64   `json:"lat" db:"lat"`
	Lon        float64   `json:"lon" db:"lon"`
	SnappedLat float64   `json:"snapped_lat" db:"snapped_lat"`
	SnappedLon float64   `json:"snapped_lon" db:"snapped_lon"`
	Timestamp  time.Time `json:"timestamp" db:"timestamp"`
}

type LocationUpdate struct {
	Lat float64 `json:"lat" binding:"required"`
	Lon float64 `json:"lon" binding:"required"`
}
