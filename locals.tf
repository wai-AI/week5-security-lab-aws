locals {
  common_tags = {
    Project     = var.project_name
    Environment = "lab"
    ManagedBy   = "terraform"
  }

  frontend_bucket_name     = "${var.project_name}-frontend-${data.aws_caller_identity.current.account_id}-${var.aws_region}"
  client_files_bucket_name = "${var.project_name}-files-${data.aws_caller_identity.current.account_id}-${var.aws_region}"
}