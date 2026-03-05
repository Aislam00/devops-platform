variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "aws_region" {
  type = string
}

variable "account_id" {
  type = string
}

variable "github_repo" {
  description = "GitHub repository in owner/repo format (e.g. Aislam00/devops-platform)"
  type        = string
}

variable "tags" {
  type    = map(string)
  default = {}
}