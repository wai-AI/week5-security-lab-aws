data "aws_ami" "app" {
  owners = ["amazon"]

  filter {
    name   = "image-id"
    values = [var.app_ami_id]
  }
}

resource "aws_launch_template" "app" {
  name_prefix   = "${var.name_prefix}-app-"
  image_id      = data.aws_ami.app.id
  instance_type = "t3.micro"
  user_data     = base64gzip(var.app_user_data)

  iam_instance_profile {
    name = var.app_instance_profile_name
  }

  network_interfaces {
    device_index                = 0
    associate_public_ip_address = false
    security_groups             = [var.app_security_group_id]
    delete_on_termination       = true
  }

  block_device_mappings {
    device_name = data.aws_ami.app.root_device_name

    ebs {
      volume_size           = 10
      volume_type           = "gp3"
      encrypted             = true
      delete_on_termination = true
    }
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  credit_specification {
    cpu_credits = "standard"
  }

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = "${var.name_prefix}-app"
    }
  }

  tag_specifications {
    resource_type = "volume"

    tags = {
      Name = "${var.name_prefix}-app-volume"
    }
  }
}