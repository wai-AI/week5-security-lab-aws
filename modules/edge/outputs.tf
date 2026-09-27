output "distribution_arn" {
  value = aws_cloudfront_distribution.main.arn
}

output "distribution_id" {
  value = aws_cloudfront_distribution.main.id
}

output "frontend_url" {
  value = "https://${aws_cloudfront_distribution.main.domain_name}"
}