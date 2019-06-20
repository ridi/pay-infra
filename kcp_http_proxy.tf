variable "kcp_http_proxy_dynamodb_table_name" {
  default = "kcp-payment-approval-requests"
}

# ECS
resource "aws_ecr_repository" "kcp_http_proxy" {
  name = "ridi/kcp-http-proxy"
  count = module.global_variables.is_prod ? 1 : 0
}

resource "aws_ecs_cluster" "kcp_http_proxy" {
  name = "kcp-http-proxy-${module.global_variables.env}"
}

# Service Discovery
resource "aws_service_discovery_private_dns_namespace" "sd_private_dns_namespace" {
  name = "${module.global_variables.env}.local"
  description = "${module.global_variables.env}"
  vpc = aws_vpc.vpc.id
}

resource "aws_service_discovery_service" "kcp_http_proxy" {
  name = "kcp"
  
  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.sd_private_dns_namespace.id

    dns_records {
      ttl = 10
      type = "A"
    }

    routing_policy = "MULTIVALUE"
  }
  
  health_check_custom_config {
    failure_threshold = 5
  }
}

# Auto Scaling
resource "aws_cloudwatch_metric_alarm" "kcp_http_proxy_cpu_high" {
  alarm_name = "kcp-http-proxy-${module.global_variables.env}-cpu-high"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods = "1"
  metric_name = "CPUUtilization"
  namespace = "AWS/ECS"
  period = "60"
  statistic = "Average"
  threshold = 80

  dimensions = {
    ClusterName = aws_ecs_cluster.kcp_http_proxy.name
    ServiceName = "kcp-http-proxy"
  }

  alarm_actions = [aws_appautoscaling_policy.kcp_http_proxy_scale_up.arn]
}

resource "aws_cloudwatch_metric_alarm" "kcp_http_proxy_cpu_low" {
  alarm_name = "kcp-http-proxy-${module.global_variables.env}-cpu-low"
  comparison_operator = "LessThanThreshold"
  evaluation_periods = "1"
  metric_name = "CPUUtilization"
  namespace = "AWS/ECS"
  period = "60"
  statistic = "Average"
  threshold = 20

  dimensions = {
    ClusterName = aws_ecs_cluster.kcp_http_proxy.name
    ServiceName = "kcp-http-proxy"
  }

  alarm_actions = [aws_appautoscaling_policy.kcp_http_proxy_scale_down.arn]
}

resource "aws_appautoscaling_target" "kcp_http_proxy_scale_target" {
  service_namespace = "ecs"
  resource_id = "service/${aws_ecs_cluster.kcp_http_proxy.name}/kcp-http-proxy"
  scalable_dimension = "ecs:service:DesiredCount"
  max_capacity = module.global_variables.is_prod ? 3 : 1
  min_capacity = 1
}

resource "aws_appautoscaling_policy" "kcp_http_proxy_scale_up" {
  name = "kcp-http-proxy-scale-up"
  service_namespace = aws_appautoscaling_target.kcp_http_proxy_scale_target.service_namespace
  resource_id = aws_appautoscaling_target.kcp_http_proxy_scale_target.resource_id
  scalable_dimension = aws_appautoscaling_target.kcp_http_proxy_scale_target.scalable_dimension

  step_scaling_policy_configuration {
    adjustment_type = "ChangeInCapacity"
    cooldown = 60
    metric_aggregation_type = "Average"

    step_adjustment {
      metric_interval_lower_bound = 0
      scaling_adjustment = 1
    }
  }

  depends_on = [
    aws_appautoscaling_target.kcp_http_proxy_scale_target
  ]
}

resource "aws_appautoscaling_policy" "kcp_http_proxy_scale_down" {
  name = "kcp-http-proxy-scale-down"
  service_namespace = aws_appautoscaling_target.kcp_http_proxy_scale_target.service_namespace
  resource_id = aws_appautoscaling_target.kcp_http_proxy_scale_target.resource_id
  scalable_dimension = aws_appautoscaling_target.kcp_http_proxy_scale_target.scalable_dimension

  step_scaling_policy_configuration {
    adjustment_type = "ChangeInCapacity"
    cooldown = 300
    metric_aggregation_type = "Average"

    step_adjustment {
      metric_interval_upper_bound = 0
      scaling_adjustment = -1
    }
  }

  depends_on = [
    aws_appautoscaling_target.kcp_http_proxy_scale_target
  ]
}

# CloudWatch
resource "aws_cloudwatch_log_group" "kcp_http_proxy_logs" {
  name = "${module.global_variables.env}.kcp-http-proxy"
  
  tags = {
    Environment = module.global_variables.env
  }
}

# Security Groups
resource "aws_security_group" "kcp_http_proxy" {
  vpc_id = aws_vpc.vpc.id
  name = "kcp-http-proxy"

  ingress {
    from_port = 80
    to_port = 80
    protocol = "TCP"
    cidr_blocks = [
      aws_vpc.vpc.cidr_block
    ]
  }
  
  # If the cidr block isn't same with '0.0.0.0/0', starting ecs tasks may be failed because it can't be able to fetch container images from aws ecr.
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "kcp-http-proxy-${module.global_variables.env}"
  }
}

# DynamoDB
resource "aws_dynamodb_table" "kcp_payment_approval_requests" {
  name = "${var.kcp_http_proxy_dynamodb_table_name}-${module.global_variables.env}"
  billing_mode = "PROVISIONED"
  read_capacity = module.global_variables.is_prod ? 3 : 1
  write_capacity = module.global_variables.is_prod ? 3 : 1
  hash_key = "id"

  attribute {
    name = "id"
    type = "S"
  }

  tags = {
    Name = var.kcp_http_proxy_dynamodb_table_name
    Environment = module.global_variables.env
  }
}
