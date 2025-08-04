package handlers

import (
	"net/http"

	"devplatform/platform-api/internal/services"
	"github.com/gin-gonic/gin"
)

func GetClusterStatus(k8sService *services.K8sService) gin.HandlerFunc {
	return func(c *gin.Context) {
		clusterName := c.Param("name")

		status, err := k8sService.GetClusterStatus(clusterName)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
			return
		}

		c.JSON(http.StatusOK, gin.H{
			"cluster": status,
		})
	}
}

func GetClusterNodes(k8sService *services.K8sService) gin.HandlerFunc {
	return func(c *gin.Context) {
		clusterName := c.Param("name")

		nodes, err := k8sService.GetNodes()
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
			return
		}

		c.JSON(http.StatusOK, gin.H{
			"cluster": clusterName,
			"nodes":   nodes,
			"count":   len(nodes),
		})
	}
}

func GetNamespaces(k8sService *services.K8sService) gin.HandlerFunc {
	return func(c *gin.Context) {
		clusterName := c.Param("name")

		namespaces, err := k8sService.GetNamespaces()
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
			return
		}

		c.JSON(http.StatusOK, gin.H{
			"cluster":    clusterName,
			"namespaces": namespaces,
			"count":      len(namespaces),
		})
	}
}
