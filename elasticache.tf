resource "aws_elasticache_replication_group" "redis" {
  automatic_failover_enabled = false
  availability_zones = [
    "ap-northeast-2a",
    "ap-northeast-2c"
  ]
  replication_group_id = "ridi-pay"
  replication_group_description = "ridi-pay"
  node_type = "cache.t2.micro"
  number_cache_clusters = 2
  parameter_group_name = "default.redis4.0"
  port = 6379
  subnet_group_name = "${aws_elasticache_subnet_group.redis.name}"
}

resource "aws_elasticache_subnet_group" "redis" {
  name = "elasticache-subnet-group"
  subnet_ids = [
    "${aws_subnet.private_2a.id}",
    "${aws_subnet.private_2c.id}"
  ]
}
