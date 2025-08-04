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

	r := gin.New()
	r.Use(gin.Logger())
	r.Use(gin.Recovery())
	r.Use(middleware.CORS())
	r.Use(middleware.RequestLogger())

	api := r.Group("/api/v1")
	{
		api.GET("/health", handlers.HealthCheck)

		api.GET("/tenants", handlers.ListTenants(tenantService))
		api.POST("/tenants", handlers.CreateTenant(tenantService))
		api.GET("/tenants/:id", handlers.GetTenant(tenantService))
		api.DELETE("/tenants/:id", handlers.DeleteTenant(tenantService))

		api.GET("/tenants/:id/costs", handlers.GetTenantCosts(costService))
		api.GET("/costs/overview", handlers.GetCostOverview(costService))

		api.GET("/clusters/:name/status", handlers.GetClusterStatus(k8sService))
		api.GET("/clusters/:name/nodes", handlers.GetClusterNodes(k8sService))
		api.GET("/clusters/:name/namespaces", handlers.GetNamespaces(k8sService))
	}

	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}

	log.Printf("Platform API starting on port %s", port)
	if err := r.Run(":" + port); err != nil {
		log.Fatalf("Failed to start server: %v", err)
	}
}
