variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "db_instance_endpoint" {
  type = string
}

variable "db_instance_port" {
  type = number
}

variable "db_name" {
  type = string
}

variable "db_master_username" {
  type = string
}

variable "rds_password_secret_arn" {
  type = string
}

variable "tags" {
  type = map(string)
  default = {}
}
