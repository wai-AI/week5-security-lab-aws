resource "aws_secretsmanager_secret" "app_db" {
  name                    = "${var.name_prefix}/app-db"
  description             = "PostgreSQL credentials for the application"
  kms_key_id              = aws_kms_key.main.arn
  recovery_window_in_days = 7
}