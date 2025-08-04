package services

import (
	"database/sql"
	"fmt"
	"strings"
	"time"

	"devplatform/platform-api/internal/models"
	"devplatform/platform-api/pkg/k8s"
	"github.com/google/uuid"
)

type TenantService struct {
	db        *sql.DB
	k8sClient *k8s.Client
}

func NewTenantService(db *sql.DB, k8sClient *k8s.Client) *TenantService {
	return &TenantService{
		db:        db,
		k8sClient: k8sClient,
	}
}

func (s *TenantService) CreateTenant(req *models.CreateTenantRequest) (*models.TenantResponse, error) {
	tenant := &models.Tenant{
		ID:          uuid.New(),
		Name:        req.Name,
		Namespace:   generateNamespace(req.Name),
		Description: req.Description,
		Owner:       req.Owner,
		Email:       req.Email,
		Status:      "creating",
		CreatedAt:   time.Now(),
		UpdatedAt:   time.Now(),
	}

	query := `
		INSERT INTO tenants (id, name, namespace, description, owner, email, status, created_at, updated_at)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
	`

	_, err := s.db.Exec(query, tenant.ID, tenant.Name, tenant.Namespace,
		tenant.Description, tenant.Owner, tenant.Email, tenant.Status,
		tenant.CreatedAt, tenant.UpdatedAt)
	if err != nil {
		return nil, fmt.Errorf("failed to create tenant: %v", err)
	}

	if err := s.k8sClient.CreateNamespace(tenant.Namespace); err != nil {
		s.updateTenantStatus(tenant.ID, "failed")
		return nil, fmt.Errorf("failed to create namespace: %v", err)
	}

	s.updateTenantStatus(tenant.ID, "active")

	return &models.TenantResponse{
		ID:          tenant.ID,
		Name:        tenant.Name,
		Namespace:   tenant.Namespace,
		Description: tenant.Description,
		Owner:       tenant.Owner,
		Email:       tenant.Email,
		Status:      "active",
		CreatedAt:   tenant.CreatedAt,
		UpdatedAt:   tenant.UpdatedAt,
	}, nil
}

func (s *TenantService) GetTenant(id uuid.UUID) (*models.TenantResponse, error) {
	var tenant models.Tenant
	query := `
		SELECT id, name, namespace, description, owner, email, status, created_at, updated_at
		FROM tenants WHERE id = $1
	`

	err := s.db.QueryRow(query, id).Scan(&tenant.ID, &tenant.Name, &tenant.Namespace,
		&tenant.Description, &tenant.Owner, &tenant.Email, &tenant.Status,
		&tenant.CreatedAt, &tenant.UpdatedAt)
	if err != nil {
		if err == sql.ErrNoRows {
			return nil, fmt.Errorf("tenant not found")
		}
		return nil, fmt.Errorf("failed to get tenant: %v", err)
	}

	resources, err := s.getTenantResources(tenant.Namespace)
	if err != nil {
		resources = nil
	}

	return &models.TenantResponse{
		ID:          tenant.ID,
		Name:        tenant.Name,
		Namespace:   tenant.Namespace,
		Description: tenant.Description,
		Owner:       tenant.Owner,
		Email:       tenant.Email,
		Status:      tenant.Status,
		Resources:   resources,
		CreatedAt:   tenant.CreatedAt,
		UpdatedAt:   tenant.UpdatedAt,
	}, nil
}

func (s *TenantService) ListTenants() ([]models.TenantResponse, error) {
	query := `
		SELECT id, name, namespace, description, owner, email, status, created_at, updated_at
		FROM tenants ORDER BY created_at DESC
	`

	rows, err := s.db.Query(query)
	if err != nil {
		return nil, fmt.Errorf("failed to list tenants: %v", err)
	}
	defer rows.Close()

	var tenants []models.TenantResponse
	for rows.Next() {
		var tenant models.Tenant
		err := rows.Scan(&tenant.ID, &tenant.Name, &tenant.Namespace,
			&tenant.Description, &tenant.Owner, &tenant.Email, &tenant.Status,
			&tenant.CreatedAt, &tenant.UpdatedAt)
		if err != nil {
			continue
		}

		tenants = append(tenants, models.TenantResponse{
			ID:          tenant.ID,
			Name:        tenant.Name,
			Namespace:   tenant.Namespace,
			Description: tenant.Description,
			Owner:       tenant.Owner,
			Email:       tenant.Email,
			Status:      tenant.Status,
			CreatedAt:   tenant.CreatedAt,
			UpdatedAt:   tenant.UpdatedAt,
		})
	}

	return tenants, nil
}

func (s *TenantService) DeleteTenant(id uuid.UUID) error {
	tenant, err := s.GetTenant(id)
	if err != nil {
		return err
	}

	if err := s.k8sClient.DeleteNamespace(tenant.Namespace); err != nil {
		return fmt.Errorf("failed to delete namespace: %v", err)
	}

	query := `DELETE FROM tenants WHERE id = $1`
	_, err = s.db.Exec(query, id)
	if err != nil {
		return fmt.Errorf("failed to delete tenant: %v", err)
	}

	return nil
}

func (s *TenantService) updateTenantStatus(id uuid.UUID, status string) error {
	query := `UPDATE tenants SET status = $1, updated_at = $2 WHERE id = $3`
	_, err := s.db.Exec(query, status, time.Now(), id)
	return err
}

func (s *TenantService) getTenantResources(namespace string) (*models.TenantResources, error) {
	pods, err := s.k8sClient.GetPodCount(namespace)
	if err != nil {
		return nil, err
	}

	return &models.TenantResources{
		Namespace:   namespace,
		Pods:        pods,
		Services:    0,
		Deployments: 0,
		CPUUsage:    "0m",
		MemoryUsage: "0Mi",
	}, nil
}

func generateNamespace(name string) string {
	namespace := strings.ToLower(name)
	namespace = strings.ReplaceAll(namespace, " ", "-")
	namespace = strings.ReplaceAll(namespace, "_", "-")
	return fmt.Sprintf("tenant-%s", namespace)
}
