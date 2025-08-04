package database

import (
	"database/sql"
	"fmt"

	_ "github.com/lib/pq"
)

func NewPostgresConnection(databaseURL string) (*sql.DB, error) {
	db, err := sql.Open("postgres", databaseURL)
	if err != nil {
		return nil, fmt.Errorf("failed to open database connection: %v", err)
	}

	if err := db.Ping(); err != nil {
		return nil, fmt.Errorf("failed to ping database: %v", err)
	}

	if err := createTables(db); err != nil {
		return nil, fmt.Errorf("failed to create tables: %v", err)
	}

	return db, nil
}

func createTables(db *sql.DB) error {
	tenantsTable := `
	CREATE TABLE IF NOT EXISTS tenants (
		id UUID PRIMARY KEY,
		name VARCHAR(255) NOT NULL UNIQUE,
		namespace VARCHAR(255) NOT NULL UNIQUE,
		description TEXT,
		owner VARCHAR(255) NOT NULL,
		email VARCHAR(255) NOT NULL,
		status VARCHAR(50) NOT NULL DEFAULT 'active',
		created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
		updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
	);
	`

	costDataTable := `
	CREATE TABLE IF NOT EXISTS cost_data (
		id SERIAL PRIMARY KEY,
		tenant_id UUID REFERENCES tenants(id) ON DELETE CASCADE,
		service VARCHAR(255) NOT NULL,
		amount DECIMAL(10,2) NOT NULL,
		currency VARCHAR(10) NOT NULL DEFAULT 'USD',
		start_date DATE NOT NULL,
		end_date DATE NOT NULL,
		granularity VARCHAR(20) NOT NULL,
		created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
	);
	`

	platformMetricsTable := `
	CREATE TABLE IF NOT EXISTS platform_metrics (
		id SERIAL PRIMARY KEY,
		metric_name VARCHAR(255) NOT NULL,
		metric_value TEXT NOT NULL,
		metric_type VARCHAR(50) NOT NULL,
		timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
		tags JSONB
	);
	`

	indexQueries := []string{
		"CREATE INDEX IF NOT EXISTS idx_tenants_status ON tenants(status);",
		"CREATE INDEX IF NOT EXISTS idx_tenants_created_at ON tenants(created_at);",
		"CREATE INDEX IF NOT EXISTS idx_cost_data_tenant_id ON cost_data(tenant_id);",
		"CREATE INDEX IF NOT EXISTS idx_cost_data_dates ON cost_data(start_date, end_date);",
		"CREATE INDEX IF NOT EXISTS idx_platform_metrics_name ON platform_metrics(metric_name);",
		"CREATE INDEX IF NOT EXISTS idx_platform_metrics_timestamp ON platform_metrics(timestamp);",
	}

	tables := []string{tenantsTable, costDataTable, platformMetricsTable}

	for _, table := range tables {
		if _, err := db.Exec(table); err != nil {
			return fmt.Errorf("failed to create table: %v", err)
		}
	}

	for _, indexQuery := range indexQueries {
		if _, err := db.Exec(indexQuery); err != nil {
			return fmt.Errorf("failed to create index: %v", err)
		}
	}

	return nil
}
