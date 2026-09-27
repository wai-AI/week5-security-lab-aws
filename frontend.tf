resource "aws_s3_object" "frontend_index" {
  bucket = module.storage.frontend_bucket_name
  key    = "index.html"

  source      = "${path.root}/app/frontend/index.html"
  source_hash = filesha256("${path.root}/app/frontend/index.html")

  content_type  = "text/html; charset=utf-8"
  cache_control = "no-cache"
}

resource "aws_s3_object" "frontend_js" {
  bucket = module.storage.frontend_bucket_name
  key    = "app.js"

  source      = "${path.root}/app/frontend/app.js"
  source_hash = filesha256("${path.root}/app/frontend/app.js")

  content_type  = "application/javascript; charset=utf-8"
  cache_control = "no-cache"
}

resource "aws_s3_object" "frontend_config" {
  bucket = module.storage.frontend_bucket_name
  key    = "config.json"

  content = jsonencode({
    client_id      = module.identity.client_id
    login_base_url = module.identity.login_base_url
    redirect_uri   = "${module.edge.frontend_url}/"
  })

  content_type  = "application/json; charset=utf-8"
  cache_control = "no-store"
}
