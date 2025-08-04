package services

import (
	"context"
	"fmt"
	"strconv"
	"time"

	"devplatform/platform-api/internal/models"
	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/service/costexplorer"
	"github.com/aws/aws-sdk-go-v2/service/costexplorer/types"
	"github.com/google/uuid"
)

type CostService struct {
	costExplorer *costexplorer.Client
}

func NewCostService(awsConfig aws.Config) *CostService {
	return &CostService{
		costExplorer: costexplorer.NewFromConfig(awsConfig),
	}
}

func (s *CostService) GetTenantCosts(tenantID uuid.UUID, req *models.CostRequest) (*models.TenantCostSummary, error) {
	startDate, err := time.Parse("2006-01-02", req.StartDate)
	if err != nil {
		return nil, fmt.Errorf("invalid start date: %v", err)
	}

	endDate, err := time.Parse("2006-01-02", req.EndDate)
	if err != nil {
		return nil, fmt.Errorf("invalid end date: %v", err)
	}

	input := &costexplorer.GetCostAndUsageInput{
		TimePeriod: &types.DateInterval{
			Start: aws.String(req.StartDate),
			End:   aws.String(req.EndDate),
		},
		Granularity: types.Granularity(req.Granularity),
		Metrics:     []string{"BlendedCost"},
		GroupBy: []types.GroupDefinition{
			{
				Type: types.GroupDefinitionTypeTag,
				Key:  aws.String("TenantID"),
			},
			{
				Type: types.GroupDefinitionTypeDimension,
				Key:  aws.String("SERVICE"),
			},
		},
		Filter: &types.Expression{
			Tags: &types.TagValues{
				Key:    aws.String("TenantID"),
				Values: []string{tenantID.String()},
			},
		},
	}

	result, err := s.costExplorer.GetCostAndUsage(context.TODO(), input)
	if err != nil {
		return nil, fmt.Errorf("failed to get cost data: %v", err)
	}

	summary := &models.TenantCostSummary{
		TenantID:    tenantID,
		TenantName:  "Unknown",
		TotalCost:   0.0,
		Currency:    "USD",
		Period:      fmt.Sprintf("%s to %s", req.StartDate, req.EndDate),
		Services:    []models.CostData{},
		LastUpdated: time.Now(),
	}

	for _, timeEntry := range result.ResultsByTime {
		for _, group := range timeEntry.Groups {
			if len(group.Metrics) > 0 {
				if blendedCost, exists := group.Metrics["BlendedCost"]; exists && blendedCost.Amount != nil {
					amount, err := strconv.ParseFloat(*blendedCost.Amount, 64)
					if err != nil {
						continue
					}

					serviceName := "Unknown"
					if len(group.Keys) > 1 {
						serviceName = group.Keys[1]
					}

					costData := models.CostData{
						TenantID:    tenantID,
						Service:     serviceName,
						Amount:      amount,
						Currency:    *blendedCost.Unit,
						StartDate:   startDate,
						EndDate:     endDate,
						Granularity: req.Granularity,
					}

					summary.Services = append(summary.Services, costData)
					summary.TotalCost += amount
				}
			}
		}
	}

	return summary, nil
}

func (s *CostService) GetPlatformCostOverview(req *models.CostRequest) (*models.PlatformCostOverview, error) {
	input := &costexplorer.GetCostAndUsageInput{
		TimePeriod: &types.DateInterval{
			Start: aws.String(req.StartDate),
			End:   aws.String(req.EndDate),
		},
		Granularity: types.Granularity(req.Granularity),
		Metrics:     []string{"BlendedCost"},
		GroupBy: []types.GroupDefinition{
			{
				Type: types.GroupDefinitionTypeDimension,
				Key:  aws.String("SERVICE"),
			},
		},
		Filter: &types.Expression{
			Tags: &types.TagValues{
				Key:    aws.String("Project"),
				Values: []string{"devplatform"},
			},
		},
	}

	result, err := s.costExplorer.GetCostAndUsage(context.TODO(), input)
	if err != nil {
		return nil, fmt.Errorf("failed to get platform cost overview: %v", err)
	}

	overview := &models.PlatformCostOverview{
		TotalCost:    0.0,
		Currency:     "USD",
		Period:       fmt.Sprintf("%s to %s", req.StartDate, req.EndDate),
		TenantCosts:  []models.TenantCostSummary{},
		ServiceCosts: []models.CostData{},
		MonthlyTrend: []models.CostData{},
		LastUpdated:  time.Now(),
	}

	startDate, _ := time.Parse("2006-01-02", req.StartDate)
	endDate, _ := time.Parse("2006-01-02", req.EndDate)

	for _, timeEntry := range result.ResultsByTime {
		for _, group := range timeEntry.Groups {
			if len(group.Metrics) > 0 {
				if blendedCost, exists := group.Metrics["BlendedCost"]; exists && blendedCost.Amount != nil {
					amount, err := strconv.ParseFloat(*blendedCost.Amount, 64)
					if err != nil {
						continue
					}

					serviceName := "Unknown"
					if len(group.Keys) > 0 {
						serviceName = group.Keys[0]
					}

					costData := models.CostData{
						Service:     serviceName,
						Amount:      amount,
						Currency:    *blendedCost.Unit,
						StartDate:   startDate,
						EndDate:     endDate,
						Granularity: req.Granularity,
					}

					overview.ServiceCosts = append(overview.ServiceCosts, costData)
					overview.TotalCost += amount
				}
			}
		}
	}

	return overview, nil
}
