resource "random_password" "play_secret" {
  length = 32
}

resource "aws_ssm_parameter" "play_secret" {
  name  = "/${var.environment}/frontend/play_secret"
  type  = "SecureString"
  value = random_password.play_secret.result
}

resource "aws_ssm_parameter" "redis_host" {
  name  = "/${var.environment}/frontend/redis/host"
  type  = "SecureString"
  value = aws_elasticache_replication_group.redis_replication_group.primary_endpoint_address
}