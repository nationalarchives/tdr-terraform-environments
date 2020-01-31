resource "aws_alb" "main" {
  name            = "tdr-frontend-lb-${var.environment}"
  subnets         = var.public_subnets
  security_groups = [aws_security_group.lb.id]
  tags = merge(
    var.common_tags,
    map("Name", "${var.app_name}-loadbalancer")
  )
}

resource "random_string" "target_group_prefix" {
  length  = 4
  upper   = false
  special = false
}

resource "aws_alb_target_group" "frontend_target" {
  name        = "frontend-tg-${random_string.target_group_prefix.result}-${var.environment}"
  port        = 9000
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    healthy_threshold   = "3"
    interval            = "30"
    protocol            = "HTTP"
    matcher             = "200,303"
    timeout             = "3"
    path                = "/"
    unhealthy_threshold = "2"
  }

  tags = merge(
    var.common_tags,
    map("Name", "${var.app_name}-target-group")
  )
}

data "aws_acm_certificate" "national_archives" {
  domain   = "tdr-${var.environment_full_name}.nationalarchives.gov.uk"
  statuses = ["ISSUED"]
}

resource "aws_alb_listener" "frontend_tls" {
  load_balancer_arn = aws_alb.main.id
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = data.aws_acm_certificate.national_archives.arn

  default_action {
    target_group_arn = aws_alb_target_group.frontend_target.arn
    type             = "forward"
  }
}

resource "aws_alb_listener" "frontend_http" {
  load_balancer_arn = aws_alb.main.id
  port              = 80
  default_action {
    type = "redirect"
    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}
