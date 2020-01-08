resource "aws_alb" "main" {
  name            = "tdr-frontend-lb-${var.environment}"
  subnets         = aws_subnet.public.*.id
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
  name        = "frontend-target-group-${random_string.target_group_prefix.result}-${var.environment}"
  port        = 9000
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
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
  domain   = "*.nationalarchives.gov.uk"
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
