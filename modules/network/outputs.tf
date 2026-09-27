output "vpc_id" {
  value = aws_vpc.main.id
}

output "public_subnet_ids" {
  value = [
    for az in var.availability_zones :
    aws_subnet.public[az].id
  ]
}

output "app_subnet_ids" {
  value = [
    for az in var.availability_zones :
    aws_subnet.private_app[az].id
  ]
}

output "db_subnet_ids" {
  value = [
    for az in var.availability_zones :
    aws_subnet.private_db[az].id
  ]
}

output "nat_gateway_id" {
  value = aws_nat_gateway.main.id
}

output "app_route_table_id" {
  value = aws_route_table.app.id
}

output "alb_security_group_id" {
  value = aws_security_group.alb.id
}

output "app_security_group_id" {
  value = aws_security_group.app.id
}

output "db_security_group_id" {
  value = aws_security_group.db.id
}

output "s3_endpoint_id" {
  value = aws_vpc_endpoint.s3.id
}

output "secrets_manager_endpoint_id" {
  value = aws_vpc_endpoint.secrets_manager.id
}