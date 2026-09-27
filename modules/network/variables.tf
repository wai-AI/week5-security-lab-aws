variable "vpc_name" {
  type        = string
  description = "VPC name"
  default     = "secure-saas-lab-vpc"
}

variable "name_prefix" {
  type        = string
  description = "Name prefix"
}

variable "vpc_cidr" {
  type        = string
  description = "VPC CIDR block"
}

variable "availability_zones" {
  type        = list(string)
  description = "List of availability zones"
}