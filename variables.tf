variable "project_name" {
  type    = string
  default = "secure-saas-lab"
}

variable "aws_region" {
  type    = string
  default = "eu-central-1"
}

variable "vpc_cidr" {
  type    = string
  default = "10.20.0.0/16"
}

variable "availability_zones" {
  type    = list(string)
  default = ["eu-central-1a", "eu-central-1b"]
}

variable "origin_verify_secret" {
  description = "Shared header value for CloudFront and ALB"
  type        = string
  sensitive   = true
}

variable "app_ami_id" {
  type = string
}