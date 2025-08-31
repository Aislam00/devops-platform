package handlers

import (
	"net/http"
	"time"

	"github.com/gin-gonic/gin"
)

type HealthResponse struct {
	Status    string    `json:"status"`
	Timestamp time.Time `json:"timestamp"`
	Version   string    `json:"version"`
	Service   string    `json:"service"`
	Uptime    string    `json:"uptime"`
}

var startTime = time.Now()

func HealthCheck(c *gin.Context) {
	response := HealthResponse{
		Status:    "healthy",
		Timestamp: time.Now(),
		Version:   "1.0.0",
		Service:   "platform-api",
		Uptime:    time.Since(startTime).String(),
	}

	c.JSON(http.StatusOK, response)
}

func MetricsHandler() gin.HandlerFunc {
	return func(c *gin.Context) {
		c.Header("Content-Type", "text/plain")
		c.String(http.StatusOK, "# Platform API metrics endpoint\n")
	}
}
