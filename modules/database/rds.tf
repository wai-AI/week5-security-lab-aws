resource "aws_db_instance" "main" {
  identifier = "${var.name_prefix}-postgres"

  engine                     = "postgres"
  engine_version             = "16.15"
  auto_minor_version_upgrade = false
  instance_class             = "db.t4g.micro"

  allocated_storage = 20
  storage_type      = "gp3"
  storage_encrypted = true
  kms_key_id        = var.kms_key_arn

  db_name  = "appdb"
  username = "dbadmin"
  port     = 5432

  manage_master_user_password   = true
  master_user_secret_kms_key_id = var.kms_key_arn

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [var.db_security_group_id]
  parameter_group_name   = aws_db_parameter_group.main.name

  multi_az            = false
  publicly_accessible = false

  backup_retention_period = 1

  deletion_protection = false
  skip_final_snapshot = true

  tags = {
    Name = "${var.name_prefix}-postgres"
  }
}