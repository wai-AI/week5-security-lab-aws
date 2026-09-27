output "kms_key_arn" {
  value = aws_kms_key.main.arn
}

output "app_role_name" {
  value = aws_iam_role.app.name
}

output "app_instance_profile_name" {
  value = aws_iam_instance_profile.app.name
}

output "app_db_secret_arn" {
  value = aws_secretsmanager_secret.app_db.arn
}