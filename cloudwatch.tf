resource "aws_cloudwatch_log_group" "backend_api_apache_access" {
  name = "${module.global_variables.env}.ridi-pay.backend.api.apache.access"

  tags {
    Environment = "${module.global_variables.env}"
  }
}

resource "aws_cloudwatch_log_group" "backend_api_apache_error" {
  name = "${module.global_variables.env}.ridi-pay.backend.api.apache.error"

  tags {
    Environment = "${module.global_variables.env}"
  }
}

resource "aws_cloudwatch_log_group" "backend_api_pg_kcp" {
  name = "${module.global_variables.env}.ridi-pay.backend.api.pg.kcp"

  tags {
    Environment = "${module.global_variables.env}"
  }
}

data "aws_sns_topic" "cloudwatch_alarm" {
  name = "cloudwatch-alarm"
}

resource "aws_cloudwatch_metric_alarm" "backend_api_alb_5xx_error" {
  count = "${module.global_variables.is_prod ? 1 : 0}"
  alarm_name = "backend_api_alb_5xx_error"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods = "1"
  metric_name = "HTTPCode_ELB_5XX_Count"
  namespace = "AWS/ApplicationELB"
  period = "300"
  statistic = "Sum"
  threshold = "10"
  alarm_actions = ["${data.aws_sns_topic.cloudwatch_alarm.arn}"]
  alarm_description = "최근 5분 동안 API ALB 5xx Error(Target 5xx 에러 제외) 10건 이상 발생"
  datapoints_to_alarm = 1
  dimensions {
    LoadBalancer = "${aws_alb.ridi_pay_backend.arn_suffix}"
  }
}

resource "aws_cloudwatch_metric_alarm" "backend_api_cpu_utilization" {
  count = "${module.global_variables.is_prod ? 1 : 0}"
  alarm_name = "backend-api-cpu-utilization"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods = "1"
  metric_name = "CpuUtilization"
  namespace = "AWS/ECS"
  period = "300"
  statistic = "Average"
  threshold = "70"
  alarm_actions = ["${data.aws_sns_topic.cloudwatch_alarm.arn}"]
  alarm_description = "최근 5분 동안 api service 평균 CpuUtilization 70% 초과"
  datapoints_to_alarm = 1
  dimensions {
    ClusterName = "${aws_ecs_cluster.ridi_pay_backend.name}"
    ServiceName = "api"
  }
}

resource "aws_cloudwatch_metric_alarm" "backend_api_memory_utilization" {
  count = "${module.global_variables.is_prod ? 1 : 0}"
  alarm_name = "backend-api-memory-utilization"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods = "1"
  metric_name = "MemoryUtilization"
  namespace = "AWS/ECS"
  period = "300"
  statistic = "Average"
  threshold = "70"
  alarm_actions = ["${data.aws_sns_topic.cloudwatch_alarm.arn}"]
  alarm_description = "최근 5분 동안 api service 평균 MemoryUtilization 70% 초과"
  datapoints_to_alarm = 1
  dimensions {
    ClusterName = "${aws_ecs_cluster.ridi_pay_backend.name}"
    ServiceName = "api"
  }
}

resource "aws_cloudwatch_metric_alarm" "backend_fluentd_cpu_utilization" {
  count = "${module.global_variables.is_prod ? 1 : 0}"
  alarm_name = "backend-fluentd-cpu-utilization"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods = "1"
  metric_name = "CpuUtilization"
  namespace = "AWS/ECS"
  period = "300"
  statistic = "Average"
  threshold = "70"
  alarm_actions = ["${data.aws_sns_topic.cloudwatch_alarm.arn}"]
  alarm_description = "최근 5분 동안 fluentd service 평균 CpuUtilization 70% 초과"
  datapoints_to_alarm = 1
  dimensions {
    ClusterName = "${aws_ecs_cluster.ridi_pay_backend.name}"
    ServiceName = "fluentd"
  }
}

resource "aws_cloudwatch_metric_alarm" "backend_fluentd_memory_utilization" {
  count = "${module.global_variables.is_prod ? 1 : 0}"
  alarm_name = "backend-fluentd-memory-utilization"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods = "1"
  metric_name = "MemoryUtilization"
  namespace = "AWS/ECS"
  period = "300"
  statistic = "Average"
  threshold = "70"
  alarm_actions = ["${data.aws_sns_topic.cloudwatch_alarm.arn}"]
  alarm_description = "최근 5분 동안 fluentd service 평균 MemoryUtilization 70% 초과"
  datapoints_to_alarm = 1
  dimensions {
    ClusterName = "${aws_ecs_cluster.ridi_pay_backend.name}"
    ServiceName = "fluentd"
  }
}

resource "aws_cloudwatch_metric_alarm" "elasticache_001_cpu_utilization" {
  count = "${module.global_variables.is_prod ? 1 : 0}"
  alarm_name = "elasticache-001-cpu-utilization"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods = "1"
  namespace = "AWS/ElastiCache"
  metric_name = "CPUUtilization"
  period = "300"
  statistic = "Average"
  threshold = "45"
  alarm_actions = ["${data.aws_sns_topic.cloudwatch_alarm.arn}"]
  alarm_description = "최근 5분 동안 ElastiCache-001 평균 CPUUtilization vCPU당 45%, 총 90% 이상 / https://docs.aws.amazon.com/ko_kr/AmazonElastiCache/latest/red-ug/CacheMetrics.WhichShouldIMonitor.html 참고"
  datapoints_to_alarm = 1
  dimensions {
    CacheClusterId = "${aws_elasticache_replication_group.redis.id}"
    CacheNodeId = "0001"
  }
}

resource "aws_cloudwatch_metric_alarm" "elasticache_001_swap_usage" {
  count = "${module.global_variables.is_prod ? 1 : 0}"
  alarm_name = "elasticache-001-swap-usage"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods = "1"
  namespace = "AWS/ElastiCache"
  metric_name = "SwapUsage"
  period = "300"
  statistic = "Maximum"
  threshold = "${50 * 1024 * 1024}"
  alarm_actions = ["${data.aws_sns_topic.cloudwatch_alarm.arn}"]
  alarm_description = "최근 5분 동안 ElastiCache-001 최대 SwapUsage 50MB 이상 / https://docs.aws.amazon.com/ko_kr/AmazonElastiCache/latest/red-ug/CacheMetrics.WhichShouldIMonitor.html 참고"
  datapoints_to_alarm = 1
  dimensions {
    CacheClusterId = "${aws_elasticache_replication_group.redis.id}"
    CacheNodeId = "0001"
  }
}

resource "aws_cloudwatch_metric_alarm" "elasticache_001_freeable_memory" {
  count = "${module.global_variables.is_prod ? 1 : 0}"
  alarm_name = "elasticache-001-freeable-memory"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods = "1"
  namespace = "AWS/ElastiCache"
  metric_name = "FreeableMemory"
  period = "300"
  statistic = "Minimum"
  threshold = "${2 * 1024 * 1024 * 1024}"
  alarm_actions = ["${data.aws_sns_topic.cloudwatch_alarm.arn}"]
  alarm_description = "최근 5분 동안 ElastiCache-001 최소 FreeableMemory 2GB(30%) 이하"
  datapoints_to_alarm = 1
  dimensions {
    CacheClusterId = "${aws_elasticache_replication_group.redis.id}"
    CacheNodeId = "0001"
  }
}

resource "aws_cloudwatch_metric_alarm" "elasticache_001_is_master" {
  count = "${module.global_variables.is_prod ? 1 : 0}"
  alarm_name = "elasticache-001-is-master"
  comparison_operator = "LessThanThreshold"
  evaluation_periods = "1"
  namespace = "AWS/ElastiCache"
  metric_name = "IsMaster"
  period = "300"
  statistic = "Minimum"
  threshold = "1"
  alarm_actions = ["${data.aws_sns_topic.cloudwatch_alarm.arn}"]
  alarm_description = "최근 5분 동안 ElastiCache-001 Node Fail 발생"
  datapoints_to_alarm = 1
  dimensions {
    CacheClusterId = "${aws_elasticache_replication_group.redis.id}"
    CacheNodeId = "0001"
  }
}

resource "aws_cloudwatch_metric_alarm" "rds_master_error_log" {
  count = "${module.global_variables.is_prod ? 1 : 0}"
  alarm_name = "rds-master-error-log"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods = "1"
  metric_name = "IncomingLogEvents"
  namespace = "AWS/Logs"
  period = "300"
  statistic = "Sum"
  threshold = "1"
  alarm_actions = ["${data.aws_sns_topic.cloudwatch_alarm.arn}"]
  alarm_description = "최근 5분 동안 RDS error log 1건 이상 발생"
  datapoints_to_alarm = 1
  dimensions {
    LogGroupName = "/aws/rds/instance/ridi-pay-prod-master/error"
  }
}

resource "aws_cloudwatch_metric_alarm" "rds_master_cpu_utilization" {
  count = "${module.global_variables.is_prod ? 1 : 0}"
  alarm_name = "rds-master-cpu-utilization"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods = "1"
  metric_name = "CPUUtilization"
  namespace = "AWS/RDS"
  period = "300"
  statistic = "Average"
  threshold = "70"
  alarm_actions = ["${data.aws_sns_topic.cloudwatch_alarm.arn}"]
  alarm_description = "최근 5분 동안 RDS master 평균 CPUUtilization 70% 이상"
  datapoints_to_alarm = 1
  dimensions {
    DBInstanceIdentifier = "ridi-pay-prod-master"
  }
}

resource "aws_cloudwatch_metric_alarm" "rds_master_freeable_memory" {
  count = "${module.global_variables.is_prod ? 1 : 0}"
  alarm_name = "rds-master-freeable-memory"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods = "1"
  namespace = "AWS/RDS"
  metric_name = "FreeableMemory"
  period = "300"
  statistic = "Minimum"
  threshold = "${100 * 1024 * 1024}"
  alarm_actions = ["${data.aws_sns_topic.cloudwatch_alarm.arn}"]
  alarm_description = "최근 5분 동안 RDS master 최소 FreeableMemory 100MB 이하"
  datapoints_to_alarm = 1
  dimensions {
    DBInstanceIdentifier = "ridi-pay-prod-master"
  }
}

resource "aws_cloudwatch_metric_alarm" "rds_master_free_storage_space" {
  count = "${module.global_variables.is_prod ? 1 : 0}"
  alarm_name = "rds-master-free-storage-space"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods = "1"
  namespace = "AWS/RDS"
  metric_name = "FreeStorageSpace"
  period = "300"
  statistic = "Minimum"
  threshold = "${75 * 1024 * 1024 * 1024}"
  alarm_actions = ["${data.aws_sns_topic.cloudwatch_alarm.arn}"]
  alarm_description = "최근 5분 동안 RDS master 최소 FreeStorageSpace 75GB(30%) 이하"
  datapoints_to_alarm = 1
  dimensions {
    DBInstanceIdentifier = "ridi-pay-prod-master"
  }
}

resource "aws_cloudwatch_metric_alarm" "rds_master_swap_usage" {
  count = "${module.global_variables.is_prod ? 1 : 0}"
  alarm_name = "rds-master-swap-usage"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods = "1"
  metric_name = "SwapUsage"
  namespace = "AWS/RDS"
  period = "300"
  statistic = "Maximum"
  threshold = "${100 * 1024 * 1024}"
  alarm_actions = ["${data.aws_sns_topic.cloudwatch_alarm.arn}"]
  alarm_description = "최근 5분 동안 최대 SwapUsage 100MB 이상"
  datapoints_to_alarm = 1
  dimensions {
    DBInstanceIdentifier = "ridi-pay-prod-master"
  }
}

resource "aws_cloudwatch_metric_alarm" "rds_master_database_connections" {
  count = "${module.global_variables.is_prod ? 1 : 0}"
  alarm_name = "rds-master-database-connections"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods = "1"
  metric_name = "DatabaseConnections"
  namespace = "AWS/RDS"
  period = "300"
  statistic = "Maximum"
  threshold = "440"
  alarm_actions = ["${data.aws_sns_topic.cloudwatch_alarm.arn}"]
  alarm_description = "최근 5분 동안 최대 DatabaseConnections 440개(70%) 이상"
  datapoints_to_alarm = 1
  dimensions {
    DBInstanceIdentifier = "ridi-pay-prod-master"
  }
}
