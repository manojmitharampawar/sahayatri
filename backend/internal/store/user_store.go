package store

import (
	"context"
	"database/sql"
	"fmt"

	"github.com/manojmitharampawar/sahayatri/backend/internal/models"
)

type UserStore struct {
	db *sql.DB
}

func NewUserStore(db *sql.DB) *UserStore {
	return &UserStore{db: db}
}

func (s *UserStore) Create(ctx context.Context, u *models.User) error {
	query := `INSERT INTO users (email, phone, password_hash) VALUES ($1, $2, $3) RETURNING id, created_at`
	return s.db.QueryRowContext(ctx, query, u.Email, u.Phone, u.PasswordHash).Scan(&u.ID, &u.CreatedAt)
}

func (s *UserStore) GetByEmail(ctx context.Context, email string) (*models.User, error) {
	u := &models.User{}
	query := `SELECT id, email, phone, password_hash, created_at FROM users WHERE email = $1`
	err := s.db.QueryRowContext(ctx, query, email).Scan(&u.ID, &u.Email, &u.Phone, &u.PasswordHash, &u.CreatedAt)
	if err == sql.ErrNoRows {
		return nil, fmt.Errorf("user not found")
	}
	return u, err
}

func (s *UserStore) GetByID(ctx context.Context, id int64) (*models.User, error) {
	u := &models.User{}
	query := `SELECT id, email, phone, password_hash, created_at FROM users WHERE id = $1`
	err := s.db.QueryRowContext(ctx, query, id).Scan(&u.ID, &u.Email, &u.Phone, &u.PasswordHash, &u.CreatedAt)
	if err == sql.ErrNoRows {
		return nil, fmt.Errorf("user not found")
	}
	return u, err
}
