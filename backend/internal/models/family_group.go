package models

import "time"

type FamilyGroup struct {
	ID        int64     `json:"id" db:"id"`
	Name      string    `json:"name" db:"name"`
	OwnerID   int64     `json:"owner_id" db:"owner_id"`
	CreatedAt time.Time `json:"created_at" db:"created_at"`
}

type FamilyMember struct {
	GroupID int64  `json:"group_id" db:"group_id"`
	UserID  int64  `json:"user_id" db:"user_id"`
	Role    string `json:"role" db:"role"`
}

type CreateFamilyGroupRequest struct {
	Name string `json:"name" binding:"required"`
}

type AddFamilyMemberRequest struct {
	UserID int64  `json:"user_id" binding:"required"`
	Role   string `json:"role" binding:"required"`
}
