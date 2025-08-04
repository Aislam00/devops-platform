package k8s

import (
	"context"
	"fmt"

	corev1 "k8s.io/api/core/v1"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
)

func (c *Client) ListNamespaces() (*corev1.NamespaceList, error) {
	namespaces, err := c.Clientset.CoreV1().Namespaces().List(context.TODO(), metav1.ListOptions{})
	if err != nil {
		return nil, fmt.Errorf("failed to list namespaces: %v", err)
	}

	return namespaces, nil
}

func (c *Client) GetNamespace(name string) (*corev1.Namespace, error) {
	namespace, err := c.Clientset.CoreV1().Namespaces().Get(context.TODO(), name, metav1.GetOptions{})
	if err != nil {
		return nil, fmt.Errorf("failed to get namespace %s: %v", name, err)
	}

	return namespace, nil
}
