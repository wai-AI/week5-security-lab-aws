locals {
  az_indexes = {
    for index, az in var.availability_zones : az => index
  }
}

resource "aws_subnet" "public" {
  for_each = local.az_indexes

  vpc_id                  = aws_vpc.main.id
  availability_zone       = each.key
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, each.value)
  map_public_ip_on_launch = false

  tags = {
    Name = "${var.name_prefix}-public-${each.key}"
  }
}

resource "aws_subnet" "private_app" {
  for_each = local.az_indexes

  vpc_id            = aws_vpc.main.id
  availability_zone = each.key
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, 10 + each.value + length(local.az_indexes))

  tags = {
    Name = "${var.name_prefix}-private-${each.key}"
  }
}

resource "aws_subnet" "private_db" {
  for_each = local.az_indexes

  vpc_id            = aws_vpc.main.id
  availability_zone = each.key
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, 20 + each.value + length(local.az_indexes))

  tags = {
    Name = "${var.name_prefix}-private-${each.key}"
  }
}