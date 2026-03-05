package config

import (
	"fmt"
	"os"
	"strconv"
	"strings"
)

type Config struct {
	DatabaseURL      string
	AWSRegion        string
	KubeConfig       string
	JWTSecret        string
	TokenIssuedAfter int64
	Environment      string
	ClusterName      string
	DomainName       string
}

func Load() *Config {
	var tokenIssuedAfter int64
	if v := os.Getenv("TOKEN_ISSUED_AFTER"); v != "" {
		parsed, err := strconv.ParseInt(v, 10, 64)
		if err != nil {
			panic(fmt.Sprintf("TOKEN_ISSUED_AFTER must be a valid unix timestamp: %v", err))
		}
		tokenIssuedAfter = parsed
	}

	return &Config{
		DatabaseURL:      getEnvRequired("DATABASE_URL"),
		AWSRegion:        getEnv("AWS_REGION", "eu-west-2"),
		KubeConfig:       getEnv("KUBECONFIG", ""),
		JWTSecret:        getEnvRequired("JWT_SECRET"),
		TokenIssuedAfter: tokenIssuedAfter,
		Environment:      getEnv("ENVIRONMENT", "development"),
		ClusterName:      getEnv("CLUSTER_NAME", "devplatform-dev"),
		DomainName:       getEnv("DOMAIN_NAME", "iasolutions.co.uk"),
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
