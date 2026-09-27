variable "name_prefix" {
  type = string
}

variable "frontend_bucket_regional_domain_name" {
  type = string
}

variable "alb_dns_name" {
  type = string
}

variable "origin_verify_secret" {
  type      = string
  sensitive = true
}