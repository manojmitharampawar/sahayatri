package store

import (
	"context"
	"database/sql"
	"fmt"

	"github.com/manojmitharampawar/sahayatri/backend/internal/models"
)

type StationStore struct {
	db *sql.DB
}

func NewStationStore(db *sql.DB) *StationStore {
	return &StationStore{db: db}
}

func (s *StationStore) GetByID(ctx context.Context, id int64) (*models.Station, error) {
	st := &models.Station{}
	query := `SELECT id, code, name, lat, lon, zone FROM stations WHERE id = $1`
	err := s.db.QueryRowContext(ctx, query, id).Scan(&st.ID, &st.Code, &st.Name, &st.Lat, &st.Lon, &st.Zone)
	if err == sql.ErrNoRows {
		return nil, fmt.Errorf("station not found")
	}
	return st, err
}

func (s *StationStore) GetByCode(ctx context.Context, code string) (*models.Station, error) {
	st := &models.Station{}
	query := `SELECT id, code, name, lat, lon, zone FROM stations WHERE code = $1`
	err := s.db.QueryRowContext(ctx, query, code).Scan(&st.ID, &st.Code, &st.Name, &st.Lat, &st.Lon, &st.Zone)
	if err == sql.ErrNoRows {
		return nil, fmt.Errorf("station not found")
	}
	return st, err
}

func (s *StationStore) Search(ctx context.Context, q string) ([]models.Station, error) {
	query := `SELECT id, code, name, lat, lon, zone FROM stations WHERE name ILIKE $1 OR code ILIKE $1 ORDER BY name LIMIT 20`
	rows, err := s.db.QueryContext(ctx, query, "%"+q+"%")
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var stations []models.Station
	for rows.Next() {
		var st models.Station
		if err := rows.Scan(&st.ID, &st.Code, &st.Name, &st.Lat, &st.Lon, &st.Zone); err != nil {
			return nil, err
		}
		stations = append(stations, st)
	}
	return stations, rows.Err()
}

func (s *StationStore) List(ctx context.Context) ([]models.Station, error) {
	query := `SELECT id, code, name, lat, lon, zone FROM stations ORDER BY name`
	rows, err := s.db.QueryContext(ctx, query)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var stations []models.Station
	for rows.Next() {
		var st models.Station
		if err := rows.Scan(&st.ID, &st.Code, &st.Name, &st.Lat, &st.Lon, &st.Zone); err != nil {
			return nil, err
		}
		stations = append(stations, st)
	}
	return stations, rows.Err()
}

func (s *StationStore) Upsert(ctx context.Context, st *models.Station) error {
	query := `INSERT INTO stations (code, name, lat, lon, zone)
		VALUES ($1, $2, $3, $4, $5)
		ON CONFLICT (code) DO UPDATE SET name = $2, lat = $3, lon = $4, zone = $5
		RETURNING id`
	return s.db.QueryRowContext(ctx, query, st.Code, st.Name, st.Lat, st.Lon, st.Zone).Scan(&st.ID)
}
