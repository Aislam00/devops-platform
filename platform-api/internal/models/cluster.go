package models

import (
	"time"
)

type ClusterStatus struct {
	Name       string    `json:"name"`
	Status     string    `json:"status"`
	Version    string    `json:"version"`
	Endpoint   string    `json:"endpoint"`
	NodeCount  int       `json:"node_count"`
	LastUpdate time.Time `json:"last_update"`
}

type NodeInfo struct {
	Name         string            `json:"name"`
	Status       string            `json:"status"`
	Role         string            `json:"role"`
	Version      string            `json:"version"`
	InstanceType string            `json:"instance_type"`
	Zone         string            `json:"zone"`
	CPU          ResourceUsage     `json:"cpu"`
	Memory       ResourceUsage     `json:"memory"`
	Labels       map[string]string `json:"labels"`
	Taints       []TaintInfo       `json:"taints"`
	CreatedAt    time.Time         `json:"created_at"`
}

type ResourceUsage struct {
	Capacity    string `json:"capacity"`
	Allocatable string `json:"allocatable"`
	Used        string `json:"used"`
	Percentage  int    `json:"percentage"`
}

type TaintInfo struct {
	Key    string `json:"key"`
	Value  string `json:"value"`
	Effect string `json:"effect"`
}

type NamespaceInfo struct {
	Name      string            `json:"name"`
	Status    string            `json:"status"`
	Labels    map[string]string `json:"labels"`
	PodCount  int               `json:"pod_count"`
	CreatedAt time.Time         `json:"created_at"`
}

type ClusterOverview struct {
	Cluster    ClusterStatus   `json:"cluster"`
	Nodes      []NodeInfo      `json:"nodes"`
	Namespaces []NamespaceInfo `json:"namespaces"`
	Metrics    ClusterMetrics  `json:"metrics"`
}

type ClusterMetrics struct {
	TotalPods        int    `json:"total_pods"`
	RunningPods      int    `json:"running_pods"`
	PendingPods      int    `json:"pending_pods"`
	FailedPods       int    `json:"failed_pods"`
	TotalCPU         string `json:"total_cpu"`
	TotalMemory      string `json:"total_memory"`
	UsedCPU          string `json:"used_cpu"`
	UsedMemory       string `json:"used_memory"`
	CPUPercentage    int    `json:"cpu_percentage"`
	MemoryPercentage int    `json:"memory_percentage"`
}
