package cache

import (
	"context"
	"encoding/json"
	"fmt"
	"log"
	"time"

	"github.com/redis/go-redis/v9"
	"github.com/manojmitharampawar/sahayatri/backend/config"
	"github.com/manojmitharampawar/sahayatri/backend/internal/models"
)

type Cache struct {
	client *redis.Client
}

func New(cfg config.RedisConfig) *Cache {
	client := redis.NewClient(&redis.Options{
		Addr:     cfg.Addr,
		Password: cfg.Password,
		DB:       cfg.DB,
	})

	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	if err := client.Ping(ctx).Err(); err != nil {
		log.Printf("Warning: Redis not available: %v (falling back to no-op cache)", err)
	} else {
		log.Println("Connected to Redis")
	}

	return &Cache{client: client}
}

func (c *Cache) SetTrainStatus(ctx context.Context, status *models.TrainStatus, ttl time.Duration) error {
	data, err := json.Marshal(status)
	if err != nil {
		return fmt.Errorf("marshal train status: %w", err)
	}
	key := "train_status:" + status.TrainNumber
	return c.client.Set(ctx, key, data, ttl).Err()
}

func (c *Cache) GetTrainStatus(ctx context.Context, trainNumber string) (*models.TrainStatus, error) {
	key := "train_status:" + trainNumber
	data, err := c.client.Get(ctx, key).Bytes()
	if err == redis.Nil {
		return nil, nil
	}
	if err != nil {
		return nil, err
	}

	var status models.TrainStatus
	if err := json.Unmarshal(data, &status); err != nil {
		return nil, err
	}
	return &status, nil
}

func (c *Cache) SetPNRStatus(ctx context.Context, pnr, status string, ttl time.Duration) error {
	key := "pnr_status:" + pnr
	return c.client.Set(ctx, key, status, ttl).Err()
}

func (c *Cache) GetPNRStatus(ctx context.Context, pnr string) (string, error) {
	key := "pnr_status:" + pnr
	result, err := c.client.Get(ctx, key).Result()
	if err == redis.Nil {
		return "", nil
	}
	return result, err
}

func (c *Cache) Close() error {
	return c.client.Close()
}
