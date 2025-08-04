package services

import (
	"context"
	"fmt"

	"devplatform/platform-api/internal/models"
	"devplatform/platform-api/pkg/k8s"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
)

type K8sService struct {
	client *k8s.Client
}

func NewK8sService(client *k8s.Client) *K8sService {
	return &K8sService{
		client: client,
	}
}

func (s *K8sService) GetClusterStatus(clusterName string) (*models.ClusterStatus, error) {
	version, err := s.client.Clientset.Discovery().ServerVersion()
	if err != nil {
		return nil, fmt.Errorf("failed to get server version: %v", err)
	}

	nodes, err := s.client.Clientset.CoreV1().Nodes().List(context.TODO(), metav1.ListOptions{})
	if err != nil {
		return nil, fmt.Errorf("failed to list nodes: %v", err)
	}

	status := &models.ClusterStatus{
		Name:       clusterName,
		Status:     "Ready",
		Version:    version.String(),
		Endpoint:   "",
		NodeCount:  len(nodes.Items),
		LastUpdate: metav1.Now().Time,
	}

	for _, node := range nodes.Items {
		for _, condition := range node.Status.Conditions {
			if condition.Type == "Ready" && condition.Status != "True" {
				status.Status = "NotReady"
				break
			}
		}
	}

	return status, nil
}

func (s *K8sService) GetNodes() ([]models.NodeInfo, error) {
	nodes, err := s.client.Clientset.CoreV1().Nodes().List(context.TODO(), metav1.ListOptions{})
	if err != nil {
		return nil, fmt.Errorf("failed to list nodes: %v", err)
	}

	var nodeInfos []models.NodeInfo
	for _, node := range nodes.Items {
		nodeInfo := models.NodeInfo{
			Name:         node.Name,
			Status:       "Ready",
			Role:         getNodeRole(node.Labels),
			Version:      node.Status.NodeInfo.KubeletVersion,
			InstanceType: node.Labels["node.kubernetes.io/instance-type"],
			Zone:         node.Labels["topology.kubernetes.io/zone"],
			Labels:       node.Labels,
			CreatedAt:    node.CreationTimestamp.Time,
		}

		for _, condition := range node.Status.Conditions {
			if condition.Type == "Ready" {
				if condition.Status == "True" {
					nodeInfo.Status = "Ready"
				} else {
					nodeInfo.Status = "NotReady"
				}
				break
			}
		}

		if node.Status.Capacity != nil {
			nodeInfo.CPU = models.ResourceUsage{
				Capacity:    node.Status.Capacity.Cpu().String(),
				Allocatable: node.Status.Allocatable.Cpu().String(),
				Used:        "0",
				Percentage:  0,
			}
			nodeInfo.Memory = models.ResourceUsage{
				Capacity:    node.Status.Capacity.Memory().String(),
				Allocatable: node.Status.Allocatable.Memory().String(),
				Used:        "0",
				Percentage:  0,
			}
		}

		for _, taint := range node.Spec.Taints {
			nodeInfo.Taints = append(nodeInfo.Taints, models.TaintInfo{
				Key:    taint.Key,
				Value:  taint.Value,
				Effect: string(taint.Effect),
			})
		}

		nodeInfos = append(nodeInfos, nodeInfo)
	}

	return nodeInfos, nil
}

func (s *K8sService) GetNamespaces() ([]models.NamespaceInfo, error) {
	namespaces, err := s.client.Clientset.CoreV1().Namespaces().List(context.TODO(), metav1.ListOptions{})
	if err != nil {
		return nil, fmt.Errorf("failed to list namespaces: %v", err)
	}

	var namespaceInfos []models.NamespaceInfo
	for _, ns := range namespaces.Items {
		pods, err := s.client.Clientset.CoreV1().Pods(ns.Name).List(context.TODO(), metav1.ListOptions{})
		podCount := 0
		if err == nil {
			podCount = len(pods.Items)
		}

		namespaceInfo := models.NamespaceInfo{
			Name:      ns.Name,
			Status:    string(ns.Status.Phase),
			Labels:    ns.Labels,
			PodCount:  podCount,
			CreatedAt: ns.CreationTimestamp.Time,
		}

		namespaceInfos = append(namespaceInfos, namespaceInfo)
	}

	return namespaceInfos, nil
}

func getNodeRole(labels map[string]string) string {
	if _, exists := labels["node-role.kubernetes.io/control-plane"]; exists {
		return "control-plane"
	}
	if _, exists := labels["node-role.kubernetes.io/master"]; exists {
		return "master"
	}
	if role, exists := labels["kubernetes.io/role"]; exists {
		return role
	}
	return "worker"
}
