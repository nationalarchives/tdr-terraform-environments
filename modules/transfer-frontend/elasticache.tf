resource "aws_elasticache_replication_group" "redis_replication_group" {
  replication_group_description = "The replication group for redis for the front end"
  replication_group_id          = "frontend-redis-${var.environment}"
  number_cache_clusters         = 1
  at_rest_encryption_enabled    = true
  engine                        = "redis"
  node_type                     = "cache.t2.micro"
  parameter_group_name          = "default.redis6.x"
  engine_version                = "6.x"
  port                          = 6379
  security_group_ids            = aws_security_group.redis.*.id
  subnet_group_name             = aws_elasticache_subnet_group.redis_subnet_group.name
}

resource "aws_elasticache_subnet_group" "redis_subnet_group" {
  name       = "frontend-subnet-group-${var.environment}"
  subnet_ids = var.private_subnets
}