package store

import (
	"context"
	"database/sql"
	"fmt"

	"github.com/manojmitharampawar/sahayatri/backend/internal/models"
)

type YatraStore struct {
	db *sql.DB
}

func NewYatraStore(db *sql.DB) *YatraStore {
	return &YatraStore{db: db}
}

func (s *YatraStore) Create(ctx context.Context, y *models.YatraCard) error {
	query := `INSERT INTO yatra_cards (user_id, pnr, train_number, boarding_station_id, destination_station_id, berth_info, journey_date, status)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8) RETURNING id, created_at`
	return s.db.QueryRowContext(ctx, query,
		y.UserID, y.PNR, y.TrainNumber, y.BoardingStationID, y.DestinationStationID,
		y.BerthInfo, y.JourneyDate, y.Status,
	).Scan(&y.ID, &y.CreatedAt)
}

func (s *YatraStore) GetByID(ctx context.Context, id int64) (*models.YatraCard, error) {
	y := &models.YatraCard{}
	query := `SELECT id, user_id, pnr, train_number, boarding_station_id, destination_station_id,
		berth_info, journey_date, status, created_at FROM yatra_cards WHERE id = $1`
	err := s.db.QueryRowContext(ctx, query, id).Scan(
		&y.ID, &y.UserID, &y.PNR, &y.TrainNumber, &y.BoardingStationID, &y.DestinationStationID,
		&y.BerthInfo, &y.JourneyDate, &y.Status, &y.CreatedAt,
	)
	if err == sql.ErrNoRows {
		return nil, fmt.Errorf("yatra card not found")
	}
	return y, err
}

func (s *YatraStore) ListByUser(ctx context.Context, userID int64) ([]models.YatraCard, error) {
	query := `SELECT id, user_id, pnr, train_number, boarding_station_id, destination_station_id,
		berth_info, journey_date, status, created_at FROM yatra_cards WHERE user_id = $1 ORDER BY journey_date DESC`
	rows, err := s.db.QueryContext(ctx, query, userID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var cards []models.YatraCard
	for rows.Next() {
		var y models.YatraCard
		if err := rows.Scan(
			&y.ID, &y.UserID, &y.PNR, &y.TrainNumber, &y.BoardingStationID, &y.DestinationStationID,
			&y.BerthInfo, &y.JourneyDate, &y.Status, &y.CreatedAt,
		); err != nil {
			return nil, err
		}
		cards = append(cards, y)
	}
	return cards, rows.Err()
}

func (s *YatraStore) UpdateStatus(ctx context.Context, id int64, status string) error {
	query := `UPDATE yatra_cards SET status = $1 WHERE id = $2`
	res, err := s.db.ExecContext(ctx, query, status, id)
	if err != nil {
		return err
	}
	n, _ := res.RowsAffected()
	if n == 0 {
		return fmt.Errorf("yatra card not found")
	}
	return nil
}

func (s *YatraStore) ListActive(ctx context.Context) ([]models.YatraCard, error) {
	query := `SELECT id, user_id, pnr, train_number, boarding_station_id, destination_station_id,
		berth_info, journey_date, status, created_at FROM yatra_cards WHERE status IN ('active', 'upcoming') ORDER BY journey_date`
	rows, err := s.db.QueryContext(ctx, query)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var cards []models.YatraCard
	for rows.Next() {
		var y models.YatraCard
		if err := rows.Scan(
			&y.ID, &y.UserID, &y.PNR, &y.TrainNumber, &y.BoardingStationID, &y.DestinationStationID,
			&y.BerthInfo, &y.JourneyDate, &y.Status, &y.CreatedAt,
		); err != nil {
			return nil, err
		}
		cards = append(cards, y)
	}
	return cards, rows.Err()
}

func (s *YatraStore) AddBreadcrumb(ctx context.Context, b *models.Breadcrumb) error {
	query := `INSERT INTO breadcrumbs (yatra_id, lat, lon, snapped_lat, snapped_lon, timestamp)
		VALUES ($1, $2, $3, $4, $5, $6) RETURNING id`
	return s.db.QueryRowContext(ctx, query,
		b.YatraID, b.Lat, b.Lon, b.SnappedLat, b.SnappedLon, b.Timestamp,
	).Scan(&b.ID)
}
