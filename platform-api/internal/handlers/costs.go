package handlers

import (
	"net/http"
	"time"

	"devplatform/platform-api/internal/models"
	"devplatform/platform-api/internal/services"
	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

func GetTenantCosts(costService *services.CostService) gin.HandlerFunc {
	return func(c *gin.Context) {
		idStr := c.Param("id")
		tenantID, err := uuid.Parse(idStr)
		if err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid tenant ID"})
			return
		}

		var req models.CostRequest
		if err := c.ShouldBindQuery(&req); err != nil {
			req = models.CostRequest{
				StartDate:   time.Now().AddDate(0, -1, 0).Format("2006-01-02"),
				EndDate:     time.Now().Format("2006-01-02"),
				Granularity: "DAILY",
				GroupBy:     "SERVICE",
			}
		}

		costs, err := costService.GetTenantCosts(tenantID, &req)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
			return
		}

		c.JSON(http.StatusOK, gin.H{
			"tenant_id": tenantID,
			"costs":     costs,
			"period":    req.StartDate + " to " + req.EndDate,
		})
	}
}

func GetCostOverview(costService *services.CostService) gin.HandlerFunc {
	return func(c *gin.Context) {
		var req models.CostRequest
		if err := c.ShouldBindQuery(&req); err != nil {
			req = models.CostRequest{
				StartDate:   time.Now().AddDate(0, -1, 0).Format("2006-01-02"),
				EndDate:     time.Now().Format("2006-01-02"),
				Granularity: "DAILY",
				GroupBy:     "SERVICE",
			}
		}

		overview, err := costService.GetPlatformCostOverview(&req)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
			return
		}

		c.JSON(http.StatusOK, overview)
	}
}
