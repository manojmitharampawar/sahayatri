package store

import (
	"context"
	"database/sql"
	"fmt"

	"github.com/manojmitharampawar/sahayatri/backend/internal/models"
)

type FamilyStore struct {
	db *sql.DB
}

func NewFamilyStore(db *sql.DB) *FamilyStore {
	return &FamilyStore{db: db}
}

func (s *FamilyStore) CreateGroup(ctx context.Context, g *models.FamilyGroup) error {
	query := `INSERT INTO family_groups (name, owner_id) VALUES ($1, $2) RETURNING id, created_at`
	return s.db.QueryRowContext(ctx, query, g.Name, g.OwnerID).Scan(&g.ID, &g.CreatedAt)
}

func (s *FamilyStore) GetGroup(ctx context.Context, id int64) (*models.FamilyGroup, error) {
	g := &models.FamilyGroup{}
	query := `SELECT id, name, owner_id, created_at FROM family_groups WHERE id = $1`
	err := s.db.QueryRowContext(ctx, query, id).Scan(&g.ID, &g.Name, &g.OwnerID, &g.CreatedAt)
	if err == sql.ErrNoRows {
		return nil, fmt.Errorf("family group not found")
	}
	return g, err
}

func (s *FamilyStore) ListGroupsByUser(ctx context.Context, userID int64) ([]models.FamilyGroup, error) {
	query := `SELECT DISTINCT fg.id, fg.name, fg.owner_id, fg.created_at
		FROM family_groups fg
		LEFT JOIN family_members fm ON fg.id = fm.group_id
		WHERE fg.owner_id = $1 OR fm.user_id = $1
		ORDER BY fg.created_at DESC`
	rows, err := s.db.QueryContext(ctx, query, userID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var groups []models.FamilyGroup
	for rows.Next() {
		var g models.FamilyGroup
		if err := rows.Scan(&g.ID, &g.Name, &g.OwnerID, &g.CreatedAt); err != nil {
			return nil, err
		}
		groups = append(groups, g)
	}
	return groups, rows.Err()
}

func (s *FamilyStore) AddMember(ctx context.Context, m *models.FamilyMember) error {
	query := `INSERT INTO family_members (group_id, user_id, role) VALUES ($1, $2, $3)`
	_, err := s.db.ExecContext(ctx, query, m.GroupID, m.UserID, m.Role)
	return err
}

func (s *FamilyStore) RemoveMember(ctx context.Context, groupID, userID int64) error {
	query := `DELETE FROM family_members WHERE group_id = $1 AND user_id = $2`
	res, err := s.db.ExecContext(ctx, query, groupID, userID)
	if err != nil {
		return err
	}
	n, _ := res.RowsAffected()
	if n == 0 {
		return fmt.Errorf("member not found")
	}
	return nil
}

func (s *FamilyStore) ListMembers(ctx context.Context, groupID int64) ([]models.FamilyMember, error) {
	query := `SELECT group_id, user_id, role FROM family_members WHERE group_id = $1`
	rows, err := s.db.QueryContext(ctx, query, groupID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var members []models.FamilyMember
	for rows.Next() {
		var m models.FamilyMember
		if err := rows.Scan(&m.GroupID, &m.UserID, &m.Role); err != nil {
			return nil, err
		}
		members = append(members, m)
	}
	return members, rows.Err()
}
