package config

import (
	"os"
)

type Config struct {
	DatabaseURL string
	AWSRegion   string
	KubeConfig  string
	JWTSecret   string
	Environment string
	ClusterName string
	DomainName  string
}

func Load() *Config {
	return &Config{
		DatabaseURL: getEnv("DATABASE_URL", "postgres://platformadmin:password@localhost:5432/platform?sslmode=disable"),
		AWSRegion:   getEnv("AWS_REGION", "eu-west-2"),
		KubeConfig:  getEnv("KUBECONFIG", ""),
		JWTSecret:   getEnv("JWT_SECRET", "dev-secret-key-change-in-production"),
		Environment: getEnv("ENVIRONMENT", "development"),
		ClusterName: getEnv("CLUSTER_NAME", "devplatform-dev"),
		DomainName:  getEnv("DOMAIN_NAME", "iasolutions.co.uk"),
	}
}

func getEnv(key, defaultValue string) string {
	if value := os.Getenv(key); value != "" {
		return value
	}
	return defaultValue
}
