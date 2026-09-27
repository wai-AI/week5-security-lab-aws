resource "aws_lb_target_group" "app" {
  name        = "${var.name_prefix}-app"
  vpc_id      = var.vpc_id
  target_type = "instance"

  port     = 443
  protocol = "HTTPS"

  health_check {
    path     = "/healthz"
    port     = "traffic-port"
    protocol = "HTTPS"
    matcher  = "200"

    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }

  tags = {
    Name = "${var.name_prefix}-app"
  }
}