module "network" {
  source = "./modules/network"

  name_prefix        = var.project_name
  vpc_cidr           = var.vpc_cidr
  availability_zones = var.availability_zones
}

module "security" {
  source = "./modules/security"

  name_prefix              = var.project_name
  client_files_bucket_name = local.client_files_bucket_name
}

module "storage" {
  source = "./modules/storage"

  frontend_bucket_name        = local.frontend_bucket_name
  client_files_bucket_name    = local.client_files_bucket_name
  kms_key_arn                 = module.security.kms_key_arn
  cloudfront_distribution_arn = module.edge.distribution_arn
}

module "database" {
  source = "./modules/database"

  name_prefix          = var.project_name
  db_subnet_ids        = module.network.db_subnet_ids
  db_security_group_id = module.network.db_security_group_id
  kms_key_arn          = module.security.kms_key_arn
}

module "compute" {
  source = "./modules/compute"

  name_prefix               = var.project_name
  vpc_id                    = module.network.vpc_id
  public_subnet_ids         = module.network.public_subnet_ids
  alb_security_group_id     = module.network.alb_security_group_id
  origin_verify_secret      = var.origin_verify_secret
  app_ami_id                = var.app_ami_id
  app_subnet_ids            = module.network.app_subnet_ids
  app_security_group_id     = module.network.app_security_group_id
  app_instance_profile_name = module.security.app_instance_profile_name

  app_user_data = templatefile(
    "${path.root}/modules/compute/templates/user_data.sh.tftpl",
    {
      aws_region = var.aws_region

      node_version = "24.21.0"
      node_sha256  = trimspace(file("${path.root}/build/node.sha256"))

      deployment_bucket = aws_s3_object.backend.bucket
      backend_key       = aws_s3_object.backend.key
      backend_sha256    = local.backend_archive_sha

      db_host              = module.database.address
      app_db_secret_arn    = module.security.app_db_secret_arn
      cognito_user_pool_id = module.identity.user_pool_id
      cognito_client_id    = module.identity.client_id

      client_files_bucket = module.storage.client_files_bucket_name
    }
  )
}

module "monitoring" {
  source = "./modules/monitoring"

  name_prefix                 = var.project_name
  db_identifier               = module.database.identifier
  alb_arn_suffix              = module.compute.alb_arn_suffix
  app_target_group_arn_suffix = module.compute.app_target_group_arn_suffix
  app_role_name               = module.security.app_role_name
}

module "edge" {
  source = "./modules/edge"

  name_prefix                          = var.project_name
  frontend_bucket_regional_domain_name = module.storage.frontend_bucket_regional_domain_name
  alb_dns_name                         = module.compute.alb_dns_name
  origin_verify_secret                 = var.origin_verify_secret
  providers = {
    aws = aws.us_east_1
  }
}

module "identity" {
  source = "./modules/identity"

  name_prefix  = var.project_name
  frontend_url = module.edge.frontend_url
}