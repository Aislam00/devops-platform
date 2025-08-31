#!/bin/bash

set -e

DOMAIN_NAME=${1:-"iasolutions.co.uk"}
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

echo "Deploying secure platform with domain: $DOMAIN_NAME"

aws eks update-kubeconfig --region eu-west-2 --name devplatform-dev

echo "Installing External Secrets Operator..."
helm repo add external-secrets https://charts.external-secrets.io
helm repo update

cat << EOF_EXTERNAL > external-secrets-values.yaml
tolerations:
  - key: platform-services
    value: "true"
    effect: NoSchedule
    operator: Equal

webhook:
  tolerations:
    - key: platform-services
      value: "true"
      effect: NoSchedule
      operator: Equal

certController:
  tolerations:
    - key: platform-services
      value: "true" 
      effect: NoSchedule
      operator: Equal
EOF_EXTERNAL

helm upgrade --install external-secrets external-secrets/external-secrets \
  -n external-secrets --create-namespace \
  -f external-secrets-values.yaml \
  --timeout=300s

cd terraform/environments/dev

terraform apply -target=module.vpc -target=module.eks -target=module.rds -target=aws_route53_record.api -target=aws_route53_record.portal -auto-approve

JWT_SECRET_NAME=$(terraform output -raw jwt_secret_name)
DATABASE_SECRET_NAME=$(terraform output -raw database_secret_name)
PLATFORM_API_ROLE_ARN=$(terraform output -raw platform_api_role_arn)
BACKSTAGE_ROLE_ARN=$(terraform output -raw backstage_role_arn)
ECR_API_REPOSITORY=$(terraform output -raw ecr_api_repository)
ECR_PORTAL_REPOSITORY=$(terraform output -raw ecr_portal_repository)
CERTIFICATE_ARN=$(terraform output -raw ssl_certificate_arn)

cd ../../

echo "Building and pushing Platform API image..."
cd platform-api
aws ecr get-login-password --region eu-west-2 | docker login --username AWS --password-stdin $ECR_API_REPOSITORY

docker build --platform linux/amd64 -t $ECR_API_REPOSITORY:latest .
docker push $ECR_API_REPOSITORY:latest

echo "Building and pushing Backstage Portal image..."
cd ../backstage
aws ecr get-login-password --region eu-west-2 | docker login --username AWS --password-stdin $ECR_PORTAL_REPOSITORY

docker build --platform linux/amd64 -t $ECR_PORTAL_REPOSITORY:latest .
docker push $ECR_PORTAL_REPOSITORY:latest

cd ../

sed -e "s|{{ .Values.jwtSecretName }}|$JWT_SECRET_NAME|g" \
    -e "s|{{ .Values.databaseSecretName }}|$DATABASE_SECRET_NAME|g" \
    -e "s|{{ .Values.platformApiRoleArn }}|$PLATFORM_API_ROLE_ARN|g" \
    -e "s|{{ .Values.ecrApiRepository }}|$ECR_API_REPOSITORY|g" \
    -e "s|{{ .Values.domainName }}|$DOMAIN_NAME|g" \
    -e "s|{{ .Values.certificateArn }}|$CERTIFICATE_ARN|g" \
    k8s/platform-api.yaml > k8s/platform-api-configured.yaml

sed -e "s|{{ .Values.databaseSecretName }}|$DATABASE_SECRET_NAME|g" \
    -e "s|{{ .Values.backstageRoleArn }}|$BACKSTAGE_ROLE_ARN|g" \
    -e "s|{{ .Values.certificateArn }}|$CERTIFICATE_ARN|g" \
    -e "s|{{ .Values.ecrPortalRepository }}|$ECR_PORTAL_REPOSITORY|g" \
    -e "s|{{ .Values.domainName }}|$DOMAIN_NAME|g" \
    k8s/backstage.yaml > k8s/backstage-configured.yaml

echo "Waiting for External Secrets Operator to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment/external-secrets -n external-secrets || echo "External Secrets may not be fully ready, continuing..."

echo "Deploying Platform API..."
kubectl apply -f k8s/platform-api-configured.yaml
kubectl rollout status deployment/platform-api -n platform-api --timeout=300s

echo "Deploying Backstage Portal..."
kubectl apply -f k8s/backstage-configured.yaml
kubectl rollout status deployment/backstage -n backstage --timeout=300s

rm -f external-secrets-values.yaml
rm -f k8s/platform-api-configured.yaml
rm -f k8s/backstage-configured.yaml

echo ""
echo "Deployment complete!"
echo "Portal: https://portal.$DOMAIN_NAME"
echo "API: https://api.$DOMAIN_NAME"
