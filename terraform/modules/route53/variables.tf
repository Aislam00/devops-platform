variable "domain_name" {
  type = string
}

variable "hosted_zone_id" {
  type = string
}

variable "api_alb_hostname" {
  type = string
}

variable "portal_alb_hostname" {
  type = string
}

variable "grafana_alb_hostname" {
  type    = string
  default = null
}

variable "prometheus_alb_hostname" {
  type    = string
  default = null
}

variable "certificate_arn" {
  type = string
}

variable "tags" {
  type = map(string)
  default = {}
}
