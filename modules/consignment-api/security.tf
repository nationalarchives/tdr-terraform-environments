resource "aws_security_group" "database" {
  name        = "${var.app_name}-database-security-group-${var.environment}"
  description = "Allow inbound access from the keycloak load balancer only"
  vpc_id      = var.vpc_id

  ingress {
    protocol        = "tcp"
    from_port       = 5432
    to_port         = 5432
    security_groups = [aws_security_group.ecs_tasks.id, var.db_migration_sg]
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

resource "aws_security_group" "lb" {
  name        = "${var.app_name}-load-balancer-security-group"
  description = "Controls access to the keycloak load balancer"
  vpc_id      = var.vpc_id

  ingress {
    protocol    = "tcp"
    from_port   = 443
    to_port     = 443
    cidr_blocks = local.environment == "intg" ? var.ip_whitelist : ["0.0.0.0/0"]
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
  description = "Allow inbound access from the keycloak load balancer only"
  vpc_id      = var.vpc_id

  ingress {
    protocol        = "tcp"
    from_port       = 8080
    to_port         = 8080
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