resource "aws_elasticache_replication_group" "redis_replication_group" {
  description                = "The replication group for redis for the front end"
  replication_group_id       = "frontend-redis-${var.environment}"
  num_cache_clusters         = 1
  at_rest_encryption_enabled = true
  engine                     = var.elasticache_engine
  node_type                  = "cache.t3.micro"
  engine_version             = var.elasticache_engine_version
  port                       = 6379
  security_group_ids         = aws_security_group.redis.*.id
  subnet_group_name          = aws_elasticache_subnet_group.redis_subnet_group.name
  apply_immediately          = true
  transit_encryption_enabled = true
  transit_encryption_mode    = var.transit_encryption_mode
}

resource "aws_elasticache_subnet_group" "redis_subnet_group" {
  name       = "frontend-subnet-group-${var.environment}"
  subnet_ids = var.private_subnets_elasticache
}
