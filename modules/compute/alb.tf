resource "aws_lb" "main" {
  name               = "${var.name_prefix}-alb"
  internal           = false
  load_balancer_type = "application"

  subnets         = var.public_subnet_ids
  security_groups = [var.alb_security_group_id]

  tags = {
    Name = "${var.name_prefix}-alb"
  }
}