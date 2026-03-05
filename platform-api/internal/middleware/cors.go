package middleware

import (
	"os"
	"strings"

	"github.com/gin-gonic/gin"
)

func CORS() gin.HandlerFunc {
	allowedOrigins := map[string]bool{
		"https://portal.iasolutions.co.uk": true,
	}

	if gin.Mode() == gin.DebugMode {
		allowedOrigins["https://localhost:3000"] = true
		allowedOrigins["http://localhost:3000"] = true
	}

	if extra := os.Getenv("CORS_ALLOWED_ORIGINS"); extra != "" {
		for _, o := range strings.Split(extra, ",") {
			if trimmed := strings.TrimSpace(o); trimmed != "" && trimmed != "*" {
				allowedOrigins[trimmed] = true
			}
		}
	}

	return gin.HandlerFunc(func(c *gin.Context) {
		requestOrigin := c.GetHeader("Origin")

		if allowedOrigins[requestOrigin] {
			c.Header("Access-Control-Allow-Origin", requestOrigin)
			c.Header("Access-Control-Allow-Credentials", "true")
			c.Header("Access-Control-Allow-Headers", "Content-Type, Authorization, X-Requested-With")
			c.Header("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS, PATCH")
			c.Header("Access-Control-Max-Age", "86400")
			c.Header("Vary", "Origin")
		}

		if c.Request.Method == "OPTIONS" {
			c.AbortWithStatus(204)
			return
		}

		c.Next()
	})
}