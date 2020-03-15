# Load Balancer
resource "aws_alb" "default" {
  name = local.cannonical_name

  security_groups    = [aws_security_group.dmz.id]
  load_balancer_type = "application"
  internal           = var.lb_is_internal

  subnets = var.lb_subnet_ids

  tags = {
    app_name        = var.app_name
    app_environment = var.app_environment
  }
}

resource "aws_alb_listener" "http" {
  load_balancer_arn = aws_alb.default.arn

  port     = 80
  protocol = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = 443
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

resource "aws_alb_listener" "https" {
  load_balancer_arn = aws_alb.default.arn

  port       = 443
  protocol   = "HTTPS"
  ssl_policy = "ELBSecurityPolicy-2016-08"

  certificate_arn = data.aws_acm_certificate.default.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.blue.arn
  }

  lifecycle {
    ignore_changes = [ default_action ]
  }
}

resource "aws_alb_target_group" "blue" {
  name        = "${local.cannonical_name}-blue"
  port        = var.docker_web_port
  protocol    = var.ecs_protocol
  vpc_id      = var.vpc_id
  target_type = "ip"

  deregistration_delay = var.lb_deregistration_delay
  slow_start = var.lb_slow_start

  health_check {
    path              = var.lb_health_check_path
    interval          = var.lb_health_check_interval
    timeout           = var.lb_health_check_timeout
    healthy_threshold = var.lb_health_check_threshold
    unhealthy_threshold = var.lb_health_failure_check_threshold
  }
}

resource "aws_alb_target_group" "green" {
  name        = "${local.cannonical_name}-green"
  port        = var.docker_web_port
  protocol    = var.ecs_protocol
  vpc_id      = var.vpc_id
  target_type = "ip"

  deregistration_delay = var.lb_deregistration_delay
  slow_start = var.lb_slow_start

  health_check {
    path              = var.lb_health_check_path
    interval          = var.lb_health_check_interval
    timeout           = var.lb_health_check_timeout
    healthy_threshold = var.lb_health_check_threshold
    unhealthy_threshold = var.lb_health_failure_check_threshold
  }
}
