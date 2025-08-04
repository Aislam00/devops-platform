package handlers

import (
	"net/http"

	"devplatform/platform-api/internal/models"
	"devplatform/platform-api/internal/services"
	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

func ListTenants(tenantService *services.TenantService) gin.HandlerFunc {
	return func(c *gin.Context) {
		tenants, err := tenantService.ListTenants()
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
			return
		}

		c.JSON(http.StatusOK, gin.H{
			"tenants": tenants,
			"count":   len(tenants),
		})
	}
}

func CreateTenant(tenantService *services.TenantService) gin.HandlerFunc {
	return func(c *gin.Context) {
		var req models.CreateTenantRequest
		if err := c.ShouldBindJSON(&req); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
			return
		}

		tenant, err := tenantService.CreateTenant(&req)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
			return
		}

		c.JSON(http.StatusCreated, gin.H{
			"tenant":  tenant,
			"message": "Tenant created successfully",
		})
	}
}

func GetTenant(tenantService *services.TenantService) gin.HandlerFunc {
	return func(c *gin.Context) {
		idStr := c.Param("id")
		id, err := uuid.Parse(idStr)
		if err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid tenant ID"})
			return
		}

		tenant, err := tenantService.GetTenant(id)
		if err != nil {
			if err.Error() == "tenant not found" {
				c.JSON(http.StatusNotFound, gin.H{"error": "Tenant not found"})
				return
			}
			c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
			return
		}

		c.JSON(http.StatusOK, gin.H{"tenant": tenant})
	}
}

func DeleteTenant(tenantService *services.TenantService) gin.HandlerFunc {
	return func(c *gin.Context) {
		idStr := c.Param("id")
		id, err := uuid.Parse(idStr)
		if err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid tenant ID"})
			return
		}

		err = tenantService.DeleteTenant(id)
		if err != nil {
			if err.Error() == "tenant not found" {
				c.JSON(http.StatusNotFound, gin.H{"error": "Tenant not found"})
				return
			}
			c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
			return
		}

		c.JSON(http.StatusOK, gin.H{
			"message": "Tenant deleted successfully",
		})
	}
}
