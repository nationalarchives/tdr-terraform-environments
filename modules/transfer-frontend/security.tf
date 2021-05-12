resource "aws_security_group" "lb" {
  name        = "${var.app_name}-load-balancer-security-group"
  description = "Controls access to the frontend load balancer"
  vpc_id      = var.vpc_id

  ingress {
    protocol    = "tcp"
    from_port   = 443
    to_port     = 443
    cidr_blocks = var.ip_allowlist
  }

  ingress {
    protocol    = "tcp"
    from_port   = 80
    to_port     = 80
    cidr_blocks = var.ip_allowlist
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    var.common_tags,
    map("Name", "${var.app_name}-load-balancer-security-group-${var.environment}")
  )
}

# Traffic to the ECS cluster should only come from the application load balancer
resource "aws_security_group" "ecs_tasks" {
  name        = "${var.app_name}-ecs-tasks-security-group-${var.environment}"
  description = "Allow inbound access from the frontend load balancer only"
  vpc_id      = var.vpc_id

  ingress {
    protocol        = "tcp"
    from_port       = local.app_port
    to_port         = local.app_port
    security_groups = [aws_security_group.lb.id]
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    var.common_tags,
    map("Name", "${var.app_name}-ecs-task-security-group-${var.environment}")
  )
}

resource "aws_security_group" "redis" {
  name        = "${var.app_name}-redis-sg-${var.environment}"
  description = "Allow inbound access from the frontend load balancer only"
  vpc_id      = var.vpc_id

  ingress {
    protocol        = "tcp"
    from_port       = 6379
    to_port         = 6379
    security_groups = [aws_security_group.ecs_tasks.id]
  }

  egress {
    protocol        = "-1"
    from_port       = 0
    to_port         = 0
    security_groups = [aws_security_group.ecs_tasks.id]
  }

  tags = merge(
    var.common_tags,
    map("Name", "${var.app_name}-database-security-group-${var.environment}")
  )
}
