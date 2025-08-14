package main

import (
	"log"
	"os"

	"devplatform/platform-api/internal/config"
	"devplatform/platform-api/internal/handlers"
	"devplatform/platform-api/internal/middleware"
	"devplatform/platform-api/internal/services"
	"devplatform/platform-api/pkg/aws"
	"devplatform/platform-api/pkg/database"
	"devplatform/platform-api/pkg/k8s"

	"github.com/gin-gonic/gin"
	"github.com/joho/godotenv"
)

func main() {
	if err := godotenv.Load(); err != nil {
		log.Printf("Warning: .env file not loaded: %v", err)
	}

	cfg := config.Load()

	// Validate JWT secret in production
	if cfg.Environment == "production" && cfg.JWTSecret == "dev-secret-key-change-in-production" {
		log.Fatal("SECURITY ERROR: Default JWT secret detected in production environment")
	}

	db, err := database.NewPostgresConnection(cfg.DatabaseURL)
	if err != nil {
		log.Fatalf("Failed to connect to database: %v", err)
	}
	defer db.Close()

	awsConfig, err := aws.NewConfig(cfg.AWSRegion)
	if err != nil {
		log.Fatalf("Failed to load AWS config: %v", err)
	}

	k8sClient, err := k8s.NewClient(cfg.KubeConfig)
	if err != nil {
		log.Fatalf("Failed to create Kubernetes client: %v", err)
	}

	costService := services.NewCostService(awsConfig)
	tenantService := services.NewTenantService(db, k8sClient)
	k8sService := services.NewK8sService(k8sClient)

	// Set production mode if not development
	if cfg.Environment != "development" {
		gin.SetMode(gin.ReleaseMode)
	}

	r := gin.New()
	r.Use(gin.Logger())
	r.Use(gin.Recovery())
	r.Use(middleware.CORS())
	r.Use(middleware.RequestLogger())

	// Add security headers
	r.Use(func(c *gin.Context) {
		c.Header("X-Content-Type-Options", "nosniff")
		c.Header("X-Frame-Options", "DENY")
		c.Header("X-XSS-Protection", "1; mode=block")
		c.Header("Strict-Transport-Security", "max-age=31536000; includeSubDomains")
		c.Next()
	})

	api := r.Group("/api/v1")

	// Public endpoints (no auth required)
	public := api.Group("/")
	{
		public.GET("/health", handlers.HealthCheck)
	}

	// Protected endpoints (auth required)
	protected := api.Group("/")
	protected.Use(middleware.AuthRequired(cfg.JWTSecret))
	{
		// Tenant management
		protected.GET("/tenants", handlers.ListTenants(tenantService))
		protected.POST("/tenants", handlers.CreateTenant(tenantService))
		protected.GET("/tenants/:id", handlers.GetTenant(tenantService))
		protected.DELETE("/tenants/:id", handlers.DeleteTenant(tenantService))

		// Cost management
		protected.GET("/tenants/:id/costs", handlers.GetTenantCosts(costService))
		protected.GET("/costs/overview", handlers.GetCostOverview(costService))

		// Cluster management
		protected.GET("/clusters/:name/status", handlers.GetClusterStatus(k8sService))
		protected.GET("/clusters/:name/nodes", handlers.GetClusterNodes(k8sService))
		protected.GET("/clusters/:name/namespaces", handlers.GetNamespaces(k8sService))
	}

	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}

	log.Printf("Platform API starting on port %s in %s mode", port, cfg.Environment)
	if err := r.Run(":" + port); err != nil {
		log.Fatalf("Failed to start server: %v", err)
	}
}
