# DevOps Platform

A self-service developer platform I built on AWS EKS that enables teams to provision environments and deploy applications without requiring deep Kubernetes knowledge. Uses Backstage for the developer portal and a custom Go API for backend operations.

## Why I Built This

After researching the challenges development teams face when waiting for platform teams to provision infrastructure, I wanted to explore building a solution that could eliminate that bottleneck. The idea was straightforward: give development teams the ability to create their own environments through a web interface while maintaining the consistency and security that platform teams need.

I chose this approach because self-service infrastructure platforms like Spacelift, AWS Service Catalog, and OpsLevel show there's real demand for this type of solution, but I wanted to understand the technical challenges of building one from scratch - with proper guardrails, cost controls, and monitoring built in from the start.

## Problem Statement

In most organizations, developers need to submit tickets and wait for platform teams to provision infrastructure. This creates delays and forces platform engineers to spend time on repetitive tasks instead of platform improvements.

Common scenarios this platform addresses:

**Development workflow bottlenecks:**
- Frontend teams waiting days for staging environments to test new features
- Backend developers unable to deploy microservices without infrastructure tickets  
- QA teams needing isolated test environments for different scenarios
- Platform teams overwhelmed with provisioning requests

**Operational challenges:**
- Inconsistent deployment patterns across teams
- Difficulty tracking resource usage and costs per team
- Manual processes that don't scale with team growth
- Security policies applied inconsistently

## Current State and My Approach

I designed this platform to solve the core infrastructure provisioning problem first, then build automation on top. Here's what I've implemented and what I plan to add:

**What's Working:**
- Service catalog and discovery through Backstage interface
- Self-service tenant creation with Kubernetes namespace provisioning
- Cost tracking API with usage monitoring
- Integrated monitoring setup with Prometheus and Grafana
- Template system foundation for different deployment types

**What I'm Planning Next:**
- Application deployment templates (currently teams need kubectl/Helm knowledge)
- Automated DNS and SSL certificate management
- Database provisioning templates
- Full GitOps integration with automatic deployments

I chose to focus on getting the infrastructure foundation solid first. Teams can already self-serve namespaces and monitoring, which eliminates most platform team tickets. The application deployment automation is the natural next step, but I wanted to validate the core concept first.

## Usage Examples

**Creating a staging environment:**
A developer accesses the portal, selects "Create New Tenant," provides basic information like team name and environment type, and receives a configured Kubernetes namespace with monitoring in approximately 10 minutes.

**API service deployment:**
Teams use available templates to deploy backend services, with automatic service discovery registration and monitoring configuration. Other teams can locate and integrate with these services through the catalog.

**Testing isolation:**
QA teams create separate environments for different test scenarios, ensuring test runs don't interfere with each other or with development work.

## Architecture

The platform runs on AWS EKS with these core components:

- **EKS Cluster** - Kubernetes orchestration using spot instances for cost efficiency
- **RDS PostgreSQL** - Persistent storage for tenant metadata and application data
- **AWS Managed Prometheus** - Metrics collection and aggregation
- **Grafana** - Monitoring dashboards and alerting
- **Platform API** - Go-based service handling tenant management and Kubernetes operations
- **Backstage Portal** - Web interface providing self-service capabilities

![Platform Architecture](screenshots/06-platform-architecture.png)

## Screenshots

Service catalog showing available components and services:

![Service Catalog Overview](screenshots/01-service-catalog-overview.png)

Component details with documentation and relationships:

![Component Details](screenshots/02-component-details-view.png)

System architecture visualization:

![System Architecture View](screenshots/03-system-architecture-view.png)

Self-service tenant creation interface:

![Developer Self-Service](screenshots/04-developer-self-service.png)

API catalog with integrated documentation:

![API Catalog Integration](screenshots/05-api-catalog-integration.png)

## CI/CD Pipeline

The platform includes a comprehensive GitHub Actions workflow that orchestrates the entire deployment process:

![GitHub Actions Pipeline](screenshots/github-actions-pipeline.png)

The pipeline handles:
- Infrastructure validation and provisioning with Terraform
- Conditional deployments based on file changes  
- Application deployments to Kubernetes with proper dependency ordering
- Monitoring setup and health checks
- Manual deployment options for specific components

Note: Infrastructure is typically destroyed between deployments for cost optimization, which is why some pipeline runs show connection errors to non-existent clusters. The workflow itself demonstrates proper CI/CD practices even when the target infrastructure isn't available.

## Technology Stack

- **AWS EKS** - Kubernetes cluster management
- **AWS Route 53** - DNS management and subdomain routing
- **AWS Certificate Manager** - SSL/TLS certificate provisioning
- **AWS Application Load Balancer** - Traffic distribution and ingress
- **AWS RDS PostgreSQL** - Database layer
- **Terraform** - Infrastructure as code
- **Backstage** - Developer portal (TypeScript/React)
- **Go** - Backend API development
- **Prometheus + Grafana** - Monitoring and observability
- **GitHub Actions** - CI/CD pipeline
- **Helm** - Kubernetes package management

## Installation

### Requirements

- AWS CLI with configured credentials
- kubectl command-line tool
- Terraform version 1.0 or higher
- Go version 1.21 or higher

### Infrastructure Deployment

```bash
# Deploy backend infrastructure
cd terraform/backend
terraform init && terraform apply

# Deploy main infrastructure components
cd ../infrastructure  
terraform init && terraform apply

# Configure kubectl for cluster access
aws eks update-kubeconfig --region eu-west-2 --name devplatform-dev
```

### Application Deployment

```bash
# Deploy platform components
kubectl apply -f k8s/platform-api-deployment.yaml
kubectl apply -f k8s/backstage-deployment.yaml

# Configure monitoring stack
cd ansible
ansible-playbook -i inventory/hosts.yml monitoring.yml
```

## Configuration

### Backstage Portal Configuration

Update `backstage/portal/app-config.yaml` with your domain and cluster information.

### Platform API Environment Variables

```bash
DATABASE_URL=postgresql://user:pass@host:5432/dbname
AWS_REGION=eu-west-2
CLUSTER_NAME=devplatform-dev
PROMETHEUS_ENDPOINT=https://aps-workspaces.eu-west-2.amazonaws.com/workspaces/ws-xxx
```

### Terraform Variables

Configure `terraform/infrastructure/terraform.tfvars`:

```hcl
project_name       = "devplatform"
environment        = "dev"
aws_region         = "eu-west-2"
domain_name        = "iasolutions.co.uk"
vpc_cidr          = "10.0.0.0/16"
kubernetes_version = "1.28"
```

## API Reference

```bash
# Create new tenant
curl -X POST https://api.iasolutions.co.uk/tenants \
  -H "Content-Type: application/json" \
  -d '{"name": "team-alpha", "namespace": "team-alpha"}'

# Retrieve cluster information
curl https://api.iasolutions.co.uk/clusters

# Get cost summary
curl https://api.iasolutions.co.uk/costs/summary
```

## Monitoring

Prometheus collects metrics from cluster components and deployed applications:

![Prometheus Monitoring](screenshots/Prometheuesup.png)

Grafana provides visualization dashboards for infrastructure monitoring and cost analysis:

![Grafana Dashboard](screenshots/Grafana-dashboard.png)

Access monitoring interfaces:
- Grafana: `https://grafana.iasolutions.co.uk`
- Prometheus: Available through port forwarding for debugging

## Security and Cost Management

**Security Implementation:**
- Worker nodes deployed in private subnets
- Encryption enabled for RDS instances and EBS volumes
- IAM roles for service accounts (IRSA) configured
- TLS encryption for all external communications

**Cost Optimization:**
- Spot instances reduce compute costs by approximately 60%
- Cluster autoscaler manages node scaling based on demand
- Resource quotas implemented per tenant to prevent overuse

Estimated monthly operational cost: approximately $125 with moderate usage.

## Troubleshooting

**Node connectivity issues:**
```bash
kubectl get nodes
kubectl describe node <node-name>
```

**Platform API debugging:**
```bash
kubectl logs -n platform-api deployment/platform-api
```

**Backstage troubleshooting:**
```bash
kubectl logs -n backstage deployment/backstage
```

**Cluster health verification:**
```bash
kubectl get componentstatuses
```

## Local Development

Run components locally for development:

```bash
# Platform API
cd platform-api
go run cmd/server/main.go

# Backstage portal
cd backstage/portal
yarn install && yarn dev
```

## Challenges I Encountered

**Route 53 and DNS Configuration:** Getting the subdomain delegation working properly was more complex than expected. Setting up the hosted zones and ensuring the DNS propagation worked correctly across different environments required several iterations and careful attention to TTL settings.

**SSL Certificate Management:** Integrating AWS Certificate Manager with the load balancer and ensuring certificates were validated and renewed automatically took considerable troubleshooting. The certificate validation process through DNS records was particularly tricky to get right.

**Load Balancer Integration:** Configuring the Application Load Balancer with proper target groups, health checks, and routing rules for multiple services required fine-tuning. Getting the ingress controller to work seamlessly with the AWS Load Balancer Controller was a learning process.

**RDS Configuration:** Setting up the PostgreSQL instance with proper security groups, subnet groups, and backup configurations while ensuring the EKS cluster could connect securely required careful network planning.

**IAM Permissions:** Getting the service account roles right took longer than expected. The AWS documentation is comprehensive but figuring out the minimal required permissions for each component required trial and error.

**Backstage Configuration:** The YAML configuration is very particular about formatting and structure. I spent a fair amount of time debugging configuration issues that turned out to be indentation problems.

**Networking in Private Subnets:** Setting up the VPC with proper NAT gateway configuration and ensuring all the networking routes worked correctly required several iterations.

**Prometheus Storage:** Initially underestimated the storage requirements for metrics retention. Had to tune the retention policies and storage configuration after running for a few weeks.

## What I'd Do Differently

If I were starting this project again, I'd probably:

- Start with a simpler database setup, maybe just using Kubernetes ConfigMaps for basic metadata
- Use Helm charts consistently instead of mixing Ansible and Helm for deployments
- Implement proper backup strategies from day one rather than adding them later
- Spend more time on the initial network design to avoid the private subnet complications

But overall, I'm happy with the architecture choices. The platform successfully eliminates the infrastructure provisioning bottleneck while maintaining security and cost controls.

## License

This project is licensed under the MIT License. See the LICENSE file for complete details.