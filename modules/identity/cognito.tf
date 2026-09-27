data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

resource "aws_cognito_user_pool" "main" {
  name           = "${var.name_prefix}-users"
  user_pool_tier = "LITE"

  username_attributes      = ["email"]
  auto_verified_attributes = ["email"]

  username_configuration {
    case_sensitive = false
  }

  admin_create_user_config {
    allow_admin_create_user_only = true
  }

  password_policy {
    minimum_length                   = 12
    require_lowercase                = true
    require_uppercase                = true
    require_numbers                  = true
    require_symbols                  = true
    temporary_password_validity_days = 7
  }

  mfa_configuration = "OFF"

  tags = {
    Name = "${var.name_prefix}-users"
  }
}

resource "aws_cognito_user_pool_client" "frontend" {
  name         = "${var.name_prefix}-frontend"
  user_pool_id = aws_cognito_user_pool.main.id

  generate_secret = false

  allowed_oauth_flows_user_pool_client = true
  allowed_oauth_flows                  = ["code"]
  allowed_oauth_scopes                 = ["openid", "email", "profile"]
  supported_identity_providers         = ["COGNITO"]

  callback_urls = ["${var.frontend_url}/"]
  logout_urls   = ["${var.frontend_url}/"]

  explicit_auth_flows = [
    "ALLOW_REFRESH_TOKEN_AUTH",
  ]

  access_token_validity  = 15
  id_token_validity      = 15
  refresh_token_validity = 1

  token_validity_units {
    access_token  = "minutes"
    id_token      = "minutes"
    refresh_token = "days"
  }

  enable_token_revocation       = true
  prevent_user_existence_errors = "ENABLED"
}

resource "aws_cognito_user_pool_domain" "main" {
  domain = "${var.name_prefix}-${data.aws_caller_identity.current.account_id}"

  user_pool_id          = aws_cognito_user_pool.main.id
  managed_login_version = 1
}