locals {
  backend_archive_path = "${path.root}/build/backend.tar.gz"
  backend_archive_sha  = filesha256(local.backend_archive_path)
}

resource "aws_s3_bucket" "deployment" {
  bucket = "${var.project_name}-deploy-${data.aws_caller_identity.current.account_id}-${var.aws_region}"

  force_destroy = true
}

resource "aws_s3_bucket_public_access_block" "deployment" {
  bucket = aws_s3_bucket.deployment.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "deployment" {
  bucket = aws_s3_bucket.deployment.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_policy" "deployment" {
  bucket = aws_s3_bucket.deployment.id

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Sid       = "DenyInsecureTransport"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"

        Resource = [
          aws_s3_bucket.deployment.arn,
          "${aws_s3_bucket.deployment.arn}/*",
        ]

        Condition = {
          Bool = {
            "aws:SecureTransport" = "false"
          }
        }
      },
    ]
  })
}

resource "aws_iam_role_policy" "deployment_read" {
  name = "${var.project_name}-deployment-read"
  role = module.security.app_role_name

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect   = "Allow"
        Action   = "s3:GetObject"
        Resource = "${aws_s3_bucket.deployment.arn}/backend/*"
      },
    ]
  })
}

resource "aws_s3_object" "backend" {
  bucket = aws_s3_bucket.deployment.id
  key    = "backend/${local.backend_archive_sha}.tar.gz"

  source      = local.backend_archive_path
  source_hash = local.backend_archive_sha

  content_type           = "application/gzip"
  server_side_encryption = "AES256"

  depends_on = [
    aws_s3_bucket_public_access_block.deployment,
    aws_s3_bucket_server_side_encryption_configuration.deployment,
    aws_s3_bucket_policy.deployment,
    aws_iam_role_policy.deployment_read,
    module.network,
    module.security,
  ]
}