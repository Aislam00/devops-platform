#!/bin/bash

set -e

DOMAIN_NAME=${1:-"iasolutions.co.uk"}
REGION="eu-west-2"
CLUSTER_NAME="devplatform-dev"

echo "Deploying DevPlatform with domain: $DOMAIN_NAME"

echo "Updating kubeconfig..."
aws eks update-kubeconfig --region $REGION --name $CLUSTER_NAME

echo "Deploying infrastructure..."
cd terraform/environments/dev
terraform apply -auto-approve

echo "Getting terraform outputs..."
JWT_SECRET_NAME=$(terraform output -raw jwt_secret_name)
DATABASE_SECRET_NAME=$(terraform output -raw database_secret_name)
PLATFORM_API_ROLE_ARN=$(terraform output -raw platform_api_role_arn)
BACKSTAGE_ROLE_ARN=$(terraform output -raw backstage_role_arn)
ECR_API_REPOSITORY=$(terraform output -raw ecr_api_repository)
ECR_PORTAL_REPOSITORY=$(terraform output -raw ecr_portal_repository)
CERTIFICATE_ARN=$(terraform output -raw ssl_certificate_arn)

cd ../../../

echo "Building and pushing images..."
./scripts/build-images.sh $ECR_API_REPOSITORY $ECR_PORTAL_REPOSITORY

echo "Deploying to Kubernetes..."
helm upgrade --install devplatform ./helm/devplatform \
  --create-namespace \
  --namespace devplatform \
  --set domain=$DOMAIN_NAME \
  --set jwtSecretName=$JWT_SECRET_NAME \
  --set databaseSecretName=$DATABASE_SECRET_NAME \
  --set platformApiRoleArn=$PLATFORM_API_ROLE_ARN \
  --set backstageRoleArn=$BACKSTAGE_ROLE_ARN \
  --set api.image.repository=$ECR_API_REPOSITORY \
  --set backstage.image.repository=$ECR_PORTAL_REPOSITORY \
  --set certificateArn=$CERTIFICATE_ARN \
  --timeout=10m \
  --wait

echo ""
echo "Deployment complete!"
echo "Portal: https://portal.$DOMAIN_NAME"
echo "API: https://api.$DOMAIN_NAME"