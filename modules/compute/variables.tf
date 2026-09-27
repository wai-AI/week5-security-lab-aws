variable "name_prefix" {
  type = string
}

variable "public_subnet_ids" {
  type = list(string)
}

variable "vpc_id" {
  type = string
}

variable "alb_security_group_id" {
  type = string
}

variable "origin_verify_secret" {
  type      = string
  sensitive = true
}

variable "app_ami_id" {
  type = string
}

variable "app_subnet_ids" {
  type = list(string)
}

variable "app_security_group_id" {
  type = string
}

variable "app_instance_profile_name" {
  type = string
}

variable "app_user_data" {
  type = string
}