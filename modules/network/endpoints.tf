data "aws_region" "current" {}

resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.${data.aws_region.current.region}.s3"
  vpc_endpoint_type = "Gateway"

  route_table_ids = [aws_route_table.app.id]

  tags = {
    Name = "${var.name_prefix}-s3-endpoint"
  }
}

resource "aws_vpc_endpoint" "secrets_manager" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${data.aws_region.current.region}.secretsmanager"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true

  subnet_ids = [
    for az in var.availability_zones :
    aws_subnet.private_app[az].id
  ]

  security_group_ids = [aws_security_group.endpoints.id]

  tags = {
    Name = "${var.name_prefix}-secrets-manager-endpoint"
  }
}