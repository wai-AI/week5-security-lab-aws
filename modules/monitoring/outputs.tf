output "app_log_group_name" {
  value = aws_cloudwatch_log_group.app.name

  depends_on = [
    aws_iam_role_policy.app_logs,
  ]
}