resource "aws_s3_bucket" "client_files" {
  bucket        = var.client_files_bucket_name
  force_destroy = true
}

resource "aws_s3_bucket_public_access_block" "client_files" {
  bucket = aws_s3_bucket.client_files.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "client_files" {
  bucket = aws_s3_bucket.client_files.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = var.kms_key_arn
    }

    bucket_key_enabled = true
  }
}