package models

import "time"

type User struct {
	ID           int64     `json:"id" db:"id"`
	Email        string    `json:"email" db:"email"`
	Phone        string    `json:"phone" db:"phone"`
	PasswordHash string    `json:"-" db:"password_hash"`
	CreatedAt    time.Time `json:"created_at" db:"created_at"`
}

type RegisterRequest struct {
	Email    string `json:"email" binding:"required,email"`
	Phone    string `json:"phone" binding:"required"`
	Password string `json:"password" binding:"required,min=8"`
}

type LoginRequest struct {
	Email    string `json:"email" binding:"required,email"`
	Password string `json:"password" binding:"required"`
}

type AuthResponse struct {
	AccessToken  string `json:"access_token"`
	RefreshToken string `json:"refresh_token"`
	User         User   `json:"user"`
}

type RefreshRequest struct {
	RefreshToken string `json:"refresh_token" binding:"required"`
}
