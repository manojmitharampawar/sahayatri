package models

import "time"

type YatraCard struct {
	ID                   int64     `json:"id" db:"id"`
	UserID               int64     `json:"user_id" db:"user_id"`
	PNR                  string    `json:"pnr" db:"pnr"`
	TrainNumber          string    `json:"train_number" db:"train_number"`
	BoardingStationID    int64     `json:"boarding_station_id" db:"boarding_station_id"`
	DestinationStationID int64     `json:"destination_station_id" db:"destination_station_id"`
	BerthInfo            string    `json:"berth_info" db:"berth_info"`
	JourneyDate          time.Time `json:"journey_date" db:"journey_date"`
	Status               string    `json:"status" db:"status"`
	CreatedAt            time.Time `json:"created_at" db:"created_at"`
}

type CreateYatraCardRequest struct {
	PNR                  string `json:"pnr" binding:"required"`
	TrainNumber          string `json:"train_number" binding:"required"`
	BoardingStationID    int64  `json:"boarding_station_id" binding:"required"`
	DestinationStationID int64  `json:"destination_station_id" binding:"required"`
	BerthInfo            string `json:"berth_info"`
	JourneyDate          string `json:"journey_date" binding:"required"`
}
