package models

import (
	"github.com/google/uuid"
	"time"
)

type Tenant struct {
	ID          uuid.UUID `json:"id" db:"id"`
	Name        string    `json:"name" db:"name"`
	Namespace   string    `json:"namespace" db:"namespace"`
	Description string    `json:"description" db:"description"`
	Owner       string    `json:"owner" db:"owner"`
	Email       string    `json:"email" db:"email"`
	Status      string    `json:"status" db:"status"`
	CreatedAt   time.Time `json:"created_at" db:"created_at"`
	UpdatedAt   time.Time `json:"updated_at" db:"updated_at"`
}

type TenantResources struct {
	TenantID    uuid.UUID `json:"tenant_id"`
	Namespace   string    `json:"namespace"`
	Pods        int       `json:"pods"`
	Services    int       `json:"services"`
	Deployments int       `json:"deployments"`
	CPUUsage    string    `json:"cpu_usage"`
	MemoryUsage string    `json:"memory_usage"`
}

type CreateTenantRequest struct {
	Name        string `json:"name" binding:"required"`
	Description string `json:"description"`
	Owner       string `json:"owner" binding:"required"`
	Email       string `json:"email" binding:"required,email"`
}

type TenantResponse struct {
	ID          uuid.UUID        `json:"id"`
	Name        string           `json:"name"`
	Namespace   string           `json:"namespace"`
	Description string           `json:"description"`
	Owner       string           `json:"owner"`
	Email       string           `json:"email"`
	Status      string           `json:"status"`
	Resources   *TenantResources `json:"resources,omitempty"`
	CreatedAt   time.Time        `json:"created_at"`
	UpdatedAt   time.Time        `json:"updated_at"`
}
