resource "aws_elasticache_replication_group" "redis" {
  count = "${module.global_variables.is_staging ? 0 : 1}"
  automatic_failover_enabled = "${module.global_variables.is_prod ? true : false}"
  availability_zones = [
    "ap-northeast-2a",
    "ap-northeast-2c"
  ]
  replication_group_id = "ridi-pay-${module.global_variables.env}"
  replication_group_description = "ridi-pay-${module.global_variables.env}"
  security_group_ids = [
    "${aws_vpc.vpc.default_security_group_id}"
  ]
  node_type = "${module.global_variables.is_prod ? "cache.m5.large" : "cache.t2.micro"}"
  number_cache_clusters = 2
  parameter_group_name = "default.redis4.0"
  port = 6379
  subnet_group_name = "${aws_elasticache_subnet_group.redis.name}"
}

resource "aws_elasticache_subnet_group" "redis" {
  count = "${module.global_variables.is_staging ? 0 : 1}"
  name = "ridi-pay-${module.global_variables.env}"
  subnet_ids = [
    "${aws_subnet.private_2a.id}",
    "${aws_subnet.private_2c.id}"
  ]
}
