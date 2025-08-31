aws_region   = "eu-west-2"
project_name = "devplatform"
environment  = "dev"
owner        = "platform-team"

domain_name = "iasolutions.co.uk"

vpc_cidr = "10.0.0.0/16"
public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
private_subnet_cidrs = ["10.0.10.0/24", "10.0.20.0/24"]

kubernetes_version = "1.28"

database_name = "platform"

allowed_cidr_blocks = ["10.0.0.0/16"]
