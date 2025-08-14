package middleware

import (
    "github.com/gin-gonic/gin"
)

func CORS() gin.HandlerFunc {
    return gin.HandlerFunc(func(c *gin.Context) {
        // Replace with your actual domain when deploying
        origin := "https://iasolutions.co.uk"
        if gin.Mode() == gin.DebugMode {
            origin = "*" // Only allow * in development
        }
        
        c.Header("Access-Control-Allow-Origin", origin)
        c.Header("Access-Control-Allow-Credentials", "true")
        c.Header("Access-Control-Allow-Headers", "Content-Type, Authorization")
        c.Header("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS")

        if c.Request.Method == "OPTIONS" {
            c.AbortWithStatus(204)
            return
        }

        c.Next()
    })
}
