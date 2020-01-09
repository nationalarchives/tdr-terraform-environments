resource "aws_elasticache_cluster" "example" {
  cluster_id           = "frontend-cache-${var.environment}"
  engine               = "redis"
  node_type            = "cache.t2.micro"
  num_cache_nodes      = 1
  parameter_group_name = "default.redis5.0"
  engine_version       = "5.0.5"
  port                 = 6379
  security_group_ids   = aws_security_group.redis.*.id
}