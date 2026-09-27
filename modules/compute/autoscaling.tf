resource "aws_autoscaling_group" "app" {
  name = "${var.name_prefix}-app-asg"

  min_size         = 1
  desired_capacity = 2
  max_size         = 3

  vpc_zone_identifier = var.app_subnet_ids
  target_group_arns   = [aws_lb_target_group.app.arn]

  health_check_type         = "ELB"
  health_check_grace_period = 600

  launch_template {
    id      = aws_launch_template.app.id
    version = tostring(aws_launch_template.app.latest_version)
  }

  tag {
    key                 = "Name"
    value               = "${var.name_prefix}-app"
    propagate_at_launch = true
  }

  depends_on = [
    aws_lb_listener_rule.cloudfront
  ]
}