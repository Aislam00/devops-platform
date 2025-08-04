package models

import (
	"github.com/google/uuid"
	"time"
)

type CostData struct {
	TenantID    uuid.UUID `json:"tenant_id,omitempty"`
	Service     string    `json:"service"`
	Amount      float64   `json:"amount"`
	Currency    string    `json:"currency"`
	StartDate   time.Time `json:"start_date"`
	EndDate     time.Time `json:"end_date"`
	Granularity string    `json:"granularity"`
}

type TenantCostSummary struct {
	TenantID    uuid.UUID  `json:"tenant_id"`
	TenantName  string     `json:"tenant_name"`
	TotalCost   float64    `json:"total_cost"`
	Currency    string     `json:"currency"`
	Period      string     `json:"period"`
	Services    []CostData `json:"services"`
	LastUpdated time.Time  `json:"last_updated"`
}

type PlatformCostOverview struct {
	TotalCost    float64             `json:"total_cost"`
	Currency     string              `json:"currency"`
	Period       string              `json:"period"`
	TenantCosts  []TenantCostSummary `json:"tenant_costs"`
	ServiceCosts []CostData          `json:"service_costs"`
	MonthlyTrend []CostData          `json:"monthly_trend"`
	LastUpdated  time.Time           `json:"last_updated"`
}

type CostRequest struct {
	StartDate   string `json:"start_date" form:"start_date"`
	EndDate     string `json:"end_date" form:"end_date"`
	Granularity string `json:"granularity" form:"granularity"`
	GroupBy     string `json:"group_by" form:"group_by"`
}
