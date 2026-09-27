output "vpc_id" {
  value = module.network.vpc_id
}

output "public_subnet_ids" {
  value = module.network.public_subnet_ids
}

output "app_subnet_ids" {
  value = module.network.app_subnet_ids
}

output "db_subnet_ids" {
  value = module.network.db_subnet_ids
}

output "nat_gateway_id" {
  value = module.network.nat_gateway_id
}

output "app_route_table_id" {
  value = module.network.app_route_table_id
}

output "frontend_bucket_name" {
  value = module.storage.frontend_bucket_name
}

output "client_files_bucket_name" {
  value = module.storage.client_files_bucket_name
}

output "db_endpoint" {
  value = module.database.endpoint
}

output "db_master_secret_arn" {
  value = module.database.master_secret_arn
}

output "frontend_url" {
  value = module.edge.frontend_url
}

output "cloudfront_distribution_id" {
  value = module.edge.distribution_id
}

output "app_asg_name" {
  value = module.compute.asg_name
}

output "app_db_secret_arn" {
  value = module.security.app_db_secret_arn
}

output "cognito_user_pool_id" {
  value = module.identity.user_pool_id
}

output "cognito_client_id" {
  value = module.identity.client_id
}

output "cognito_login_base_url" {
  value = module.identity.login_base_url
}