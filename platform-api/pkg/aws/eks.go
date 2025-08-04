package aws

import (
	"context"
	"fmt"

	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/service/eks"
)

type EKSClient struct {
	client *eks.Client
}

func NewEKSClient(cfg aws.Config) *EKSClient {
	return &EKSClient{
		client: eks.NewFromConfig(cfg),
	}
}

func (e *EKSClient) DescribeCluster(clusterName string) (*eks.DescribeClusterOutput, error) {
	input := &eks.DescribeClusterInput{
		Name: aws.String(clusterName),
	}

	result, err := e.client.DescribeCluster(context.TODO(), input)
	if err != nil {
		return nil, fmt.Errorf("failed to describe cluster %s: %v", clusterName, err)
	}

	return result, nil
}
