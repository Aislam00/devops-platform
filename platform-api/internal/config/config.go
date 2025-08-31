package config

import (
	"fmt"
	"os"
	"strings"
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
		DatabaseURL: getEnvRequired("DATABASE_URL"),
		AWSRegion:   getEnv("AWS_REGION", "eu-west-2"),
		KubeConfig:  getEnv("KUBECONFIG", ""),
		JWTSecret:   getEnvRequired("JWT_SECRET"),
		Environment: getEnv("ENVIRONMENT", "development"),
		ClusterName: getEnv("CLUSTER_NAME", "devplatform-dev"),
		DomainName:  getEnv("DOMAIN_NAME", "iasolutions.co.uk"),
	}
}

func getEnv(key, defaultValue string) string {
	if value := os.Getenv(key); value != "" {
		return strings.TrimSpace(value)
	}
	return defaultValue
}

func getEnvRequired(key string) string {
	value := strings.TrimSpace(os.Getenv(key))
	if value == "" {
		panic(fmt.Sprintf("Required environment variable %s is not set", key))
	}
	return value
}
