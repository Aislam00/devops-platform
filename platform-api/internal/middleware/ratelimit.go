package middleware

import (
	"net/http"
	"sync"
	"time"

	"github.com/gin-gonic/gin"
)

type rateLimitClient struct {
	limiter  *time.Ticker
	lastSeen time.Time
	requests int
}

type rateLimiter struct {
	clients    map[string]*rateLimitClient
	mu         sync.RWMutex
	maxClients int
}

var limiter = &rateLimiter{
	clients:    make(map[string]*rateLimitClient),
	maxClients: 1000,
}

func RateLimit() gin.HandlerFunc {
	go limiter.cleanupClients()

	return func(c *gin.Context) {
		ip := c.ClientIP()

		limiter.mu.Lock()

		if len(limiter.clients) > limiter.maxClients {
			limiter.mu.Unlock()
			c.JSON(http.StatusTooManyRequests, gin.H{"error": "Server overloaded"})
			c.Abort()
			return
		}

		clientInfo, exists := limiter.clients[ip]
		if !exists {
			clientInfo = &rateLimitClient{
				limiter:  time.NewTicker(time.Second / 5),
				lastSeen: time.Now(),
				requests: 0,
			}
			limiter.clients[ip] = clientInfo
		}

		clientInfo.lastSeen = time.Now()
		clientInfo.requests++

		limiter.mu.Unlock()

		select {
		case <-clientInfo.limiter.C:
			c.Next()
		default:
			c.JSON(http.StatusTooManyRequests, gin.H{"error": "Rate limit exceeded"})
			c.Abort()
		}
	}
}

func (rl *rateLimiter) cleanupClients() {
	ticker := time.NewTicker(time.Minute)
	defer ticker.Stop()

	for range ticker.C {
		rl.mu.Lock()
		for ip, clientInfo := range rl.clients {
			if time.Since(clientInfo.lastSeen) > time.Minute*5 {
				clientInfo.limiter.Stop()
				delete(rl.clients, ip)
			}
		}
		rl.mu.Unlock()
	}
}
