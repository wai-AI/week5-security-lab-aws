variable "name_prefix" {
  type = string
}

variable "db_subnet_ids" {
  type = list(string)
}

variable "db_security_group_id" {
  type = string
}

variable "kms_key_arn" {
  type = string
}