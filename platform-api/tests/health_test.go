package tests

import (
	"net/http"
	"net/http/httptest"
	"testing"

	"devplatform/platform-api/internal/handlers"
	"github.com/gin-gonic/gin"
)

func TestHealthCheck(t *testing.T) {
	gin.SetMode(gin.TestMode)
	w := httptest.NewRecorder()
	c, _ := gin.CreateTestContext(w)

	handlers.HealthCheck(c)

	if w.Code != http.StatusOK {
		t.Errorf("Expected status 200, got %d", w.Code)
	}
}
