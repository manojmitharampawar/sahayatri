package ws

import (
	"log"
	"sync"
)

// Hub maintains active rooms for yatra live sharing.
type Hub struct {
	mu    sync.RWMutex
	rooms map[int64]map[*Client]bool
}

func NewHub() *Hub {
	return &Hub{
		rooms: make(map[int64]map[*Client]bool),
	}
}

func (h *Hub) Register(yatraID int64, client *Client) {
	h.mu.Lock()
	defer h.mu.Unlock()

	if h.rooms[yatraID] == nil {
		h.rooms[yatraID] = make(map[*Client]bool)
	}
	h.rooms[yatraID][client] = true
	log.Printf("Client joined room %d (total: %d)", yatraID, len(h.rooms[yatraID]))
}

func (h *Hub) Unregister(yatraID int64, client *Client) {
	h.mu.Lock()
	defer h.mu.Unlock()

	if clients, ok := h.rooms[yatraID]; ok {
		delete(clients, client)
		if len(clients) == 0 {
			delete(h.rooms, yatraID)
		}
		log.Printf("Client left room %d", yatraID)
	}
}

// Broadcast sends a message to all clients in a given yatra room.
func (h *Hub) Broadcast(yatraID int64, message []byte) {
	h.mu.RLock()
	defer h.mu.RUnlock()

	clients, ok := h.rooms[yatraID]
	if !ok {
		return
	}

	for client := range clients {
		select {
		case client.Send <- message:
		default:
			close(client.Send)
			delete(clients, client)
		}
	}
}
