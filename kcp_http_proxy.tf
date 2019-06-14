variable "kcp_dynamodb_table_name" {
  default = "t_payment_approval_requests"
}

# ECS
resource "aws_ecr_repository" "kcp" {
  name = "ridi/kcp"
  count = module.global_variables.is_test ? 1 : 0
}

resource "aws_ecs_cluster" "kcp" {
  name = "kcp-${module.global_variables.env}"
}

resource "aws_iam_role" "kcp_esc_task_execution_role" {
  name = "kcp-${module.global_variables.env}-ecs-task-exec-role"
  assume_role_policy = data.aws_iam_policy_document.kcp_assume_role_policy.json
}

data "aws_iam_policy_document" "kcp_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "kcp_esc_task_execution_role_policy" {
  role = aws_iam_role.kcp_esc_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Service Discovery
resource "aws_service_discovery_private_dns_namespace" "kcp" {
  name = "local"
  description = "kcp-${module.global_variables.env}"
  vpc = aws_vpc.vpc.id
}

resource "aws_service_discovery_service" "kcp" {
  name = "${module.global_variables.env}.kcp"
  
  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.kcp.id

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
resource "aws_cloudwatch_metric_alarm" "kcp_cpu_high" {
  alarm_name = "kcp-${module.global_variables.env}-cpu-high-${var.ecs_as_cpu_high_threshold_per}"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods = "1"
  metric_name = "CPUUtilization"
  namespace = "AWS/ECS"
  period = "60"
  statistic = "Average"
  threshold = 80

  dimensions = {
    ClusterName = aws_ecs_cluster.kcp.name
    ServiceName = aws_ecs_service.kcp.name
  }

  alarm_actions = [aws_appautoscaling_policy.kcp_scale_up.arn]
}

resource "aws_cloudwatch_metric_alarm" "kcp_cpu_low" {
  alarm_name = "kcp-${module.global_variables.env}-cpu-low-${var.ecs_as_cpu_low_threshold_per}"
  comparison_operator = "LessThanThreshold"
  evaluation_periods = "1"
  metric_name = "CPUUtilization"
  namespace = "AWS/ECS"
  period = "60"
  statistic = "Average"
  threshold = 20

  dimensions = {
    ClusterName = aws_ecs_cluster.kcp.name
    ServiceName = aws_ecs_service.kcp.name
  }

  alarm_actions = [aws_appautoscaling_policy.kcp_scale_down.arn]
}

resource "aws_appautoscaling_target" "kcp_scale_target" {
  service_namespace = "ecs"
  resource_id = "service/${aws_ecs_cluster.kcp.name}/${aws_ecs_service.kcp.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  max_capacity = module.global_variables.is_prod ? 3 : 1
  min_capacity = 1
}

resource "aws_appautoscaling_policy" "kcp_scale_up" {
  name = "kcp-scale-up"
  service_namespace = aws_appautoscaling_target.kcp_scale_target.service_namespace
  resource_id = aws_appautoscaling_target.kcp_scale_target.resource_id
  scalable_dimension = aws_appautoscaling_target.kcp_scale_target.scalable_dimension

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
    aws_appautoscaling_target.kcp_scale_target
  ]
}

resource "aws_appautoscaling_policy" "kcp_scale_down" {
  name = "app-scale-down"
  service_namespace = aws_appautoscaling_target.kcp_scale_target.service_namespace
  resource_id = aws_appautoscaling_target.kcp_scale_target.resource_id
  scalable_dimension = aws_appautoscaling_target.kcp_scale_target.scalable_dimension

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
    aws_appautoscaling_target.kcp_scale_target
  ]
}

# CloudWatch
resource "aws_cloudwatch_log_group" "kcp_logs" {
  name = "/fargate/service/kcp-${module.global_variables.env}"
  
  tags = {
    Environment = module.global_variables.env
  }
}

# Security Groups
resource "aws_security_group" "kcp" {
  vpc_id = aws_vpc.vpc.id
  name = "kcp-${module.global_variables.env}-security-group"

  ingress {
    from_port = 80
    to_port = 80
    protocol = "TCP"
    cidr_blocks = [
      aws_vpc.vpc.cidr_block
    ]
  }
  
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = [
      aws_vpc.vpc.cidr_block
    ]
  }

  tags = {
    Name = "kcp-${module.global_variables.env}"
  }
}

# DynamoDB
resource "aws_dynamodb_table" "kcp_approvals" {
  count = module.global_variables.is_test ? 1 : 0
  name = var.kcp_dynamodb_table_name
  billing_mode = "PROVISIONED"
  read_capacity = module.global_variables.is_prod ? 3 : 1
  write_capacity = module.global_variables.is_prod ? 3 : 1
  hash_key = "id"

  attribute {
    name = "id"
    type = "S"
  }

  tags = {
    Name = var.kcp_dynamodb_table_name
    Environment = module.global_variables.env
  }
}
