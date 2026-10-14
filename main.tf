locals {
  envs    = toset(["blue", "green"])
  weights = { blue = var.blue_weight, green = var.green_weight }
}



# --- Existing network lookups ---
data "aws_vpc" "this" {
  filter {
    name   = "tag:Name"
    values = [var.vpc_name]
  }
}

data "aws_subnet" "public" {
  for_each = toset(var.subnet_names)

  filter {
    name   = "tag:Name"
    values = [each.value]
  }
}


data "aws_security_group" "ssh" {
  filter {
    name   = "tag:Name"
    values = [var.sg_ssh_name]
  }
}


data "aws_security_group" "http" {
  filter {
    name   = "tag:Name"
    values = [var.sg_http_name]
  }
}


data "aws_security_group" "lb" {
  filter {
    name   = "tag:Name"
    values = [var.sg_lb_name]
  }
}

data "aws_ssm_parameter" "ami" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}





# --- ALB ---


resource "aws_lb" "this" {
  name               = "${var.prefix}-lb"
  load_balancer_type = "application"
  subnets            = [for s in data.aws_subnet.public : s.id]
  security_groups    = [data.aws_security_group.lb.id]

  tags = merge(var.tags, {
    Name = "${var.prefix}-alb"
  })
}

resource "aws_lb_target_group" "env" {

  for_each = local.envs

  name     = "${var.prefix}-${each.key}-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.this.id

  health_check {
    path = "/"
  }

  tags = merge(var.tags, {
    Name = "${var.prefix}-${each.key}-tg"
  })

}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.this.arn
  port              = 80
  protocol          = "HTTP"


  default_action {
    type = "forward"
    forward {
      target_group {
        arn    = aws_lb_target_group.env["blue"].arn
        weight = var.blue_weight
      }

      target_group {
        arn    = aws_lb_target_group.env["green"].arn
        weight = var.green_weight
      }
    }


  }

  tags = merge(var.tags, {
    Name = "${var.prefix}-http-listener"
  })
}


# --- Launch templates ---
# Launch template for blue and green environments

resource "aws_launch_template" "env" {
  for_each               = local.envs
  name                   = "${var.prefix}-${each.key}-template"
  image_id               = data.aws_ssm_parameter.ami.value
  instance_type          = var.instance_type
  vpc_security_group_ids = [data.aws_security_group.ssh.id, data.aws_security_group.http.id]

  user_data = base64encode(<<-EOF
    #!/bin/bash
    dnf install -y httpd
    echo "<h1>${title(each.key)} Environment</h1>" > /var/www/html/index.html
    systemctl enable --now httpd
    EOF
  )

  tag_specifications {
    resource_type = "instance"
    tags = merge(var.tags, {
      Name = "${var.prefix}-${each.key}-instance"
    })
  }
  tags = merge(var.tags, {
    Name = "${var.prefix}-${each.key}-template"
  })
}


# --- ASGs ---

resource "aws_autoscaling_group" "env" {
  for_each = local.envs

  name                = "${var.prefix}-${each.key}-asg"
  min_size            = 1
  max_size            = 2
  desired_capacity    = 1
  vpc_zone_identifier = [for s in data.aws_subnet.public : s.id]

  target_group_arns = [aws_lb_target_group.env[each.key].arn]
  health_check_type = "ELB"

  launch_template {
    id      = aws_launch_template.env[each.key].id
    version = "$Latest"
  }

  dynamic "tag" {
    for_each = merge(var.tags, {
      Name = "${var.prefix}-${each.key}-asg"
    })

    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }


}
