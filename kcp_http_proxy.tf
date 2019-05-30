variable "kcp_certificate_domain" {
  default = {
    "prod" = "kcp.ridibooks.com"
    "staging" = "kcp.ridibooks.com"
    "test" = "kcp.ridi.io"
  }
}

variable "kcp_fargate_cpu" {
  description = "Fargate instance CPU units to provision (1 vCPU = 1024 CPU units)"
  default = {
    "prod" = 256
    "test" = 256
  }
}

variable "kcp_fargate_memory" {
  description = "Fargate instance memory to provision (in MiB)"
  default = {
    "prod" = 512
    "test" = 512
  }
}

variable "kcp_fargate_host_port" {
  default = 80  
}

variable "kcp_fargate_container_port" {
  default = 80
}

variable "kcp_dynamodb_table_name" {
  default = "t_payment_approval_requests"
}

variable "kcp_dynamodb_stage" {
  description = "KCP DynamoDB Stage"
  default = {
    prod = "production"
    test = "test"
  }
}

variable "ecs_as_cpu_low_threshold_per" {
  default = "20"
}

variable "ecs_as_cpu_high_threshold_per" {
  default = "80"
}

# ELB
resource "aws_alb_target_group" "kcp" {
  name = "kcp-http-proxy-albtg-${module.global_variables.env}"
  port = "${var.kcp_fargate_container_port}"
  protocol = "HTTP"
  vpc_id = "${aws_vpc.vpc.id}"
  deregistration_delay = 15
  target_type = "ip"
  
  health_check = {
    path = "/"
    timeout = 10
    healthy_threshold = 2
    unhealthy_threshold = 2
    interval = 15
    matcher = "200"
  }
}

resource "aws_alb" "kcp" {
  name = "kcp-http-proxy-alb-${module.global_variables.env}"
  subnets = [
    "${aws_subnet.public_2a.id}",
    "${aws_subnet.public_2c.id}"
  ]
  security_groups = [
    "${aws_security_group.kcp.id}"
  ]
  internal = true
}

data "aws_acm_certificate" "kcp" {
  domain = "${var.kcp_certificate_domain["${module.global_variables.env}"]}"
}

resource "aws_alb_listener" "kcp_ssl" {
  load_balancer_arn = "${aws_alb.kcp.id}"
  port = "443"
  protocol = "HTTPS"
  ssl_policy = "ELBSecurityPolicy-TLS-1-1-2017-01"
  certificate_arn = "${data.aws_acm_certificate.kcp.arn}"
  
  default_action {
    target_group_arn = "${aws_alb_target_group.kcp.arn}"
    type = "forward"
  }
}

resource "aws_alb_listener" "kcp" {
  load_balancer_arn = "${aws_alb.kcp.id}"
  port = "80"
  protocol = "HTTP"
  
  default_action {
    target_group_arn = "${aws_alb_target_group.kcp.arn}"
    type = "forward"
  }
}

# ECS
resource "aws_ecr_repository" "kcp" {
  count = "${module.global_variables.is_prod ? 1 : 0}"
  name = "ridi/kcp"
}

resource "aws_ecs_cluster" "kcp" {
  name = "kcp-${module.global_variables.env}"
}

resource "aws_iam_role" "kcp_esc_task_execution_role" {
  name = "kcp-${module.global_variables.env}-ecs-task-exec-role"
  assume_role_policy = "${data.aws_iam_policy_document.kcp_assume_role_policy.json}"
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
  role = "${aws_iam_role.kcp_esc_task_execution_role.name}"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_ecs_task_definition" "kcp" {#TODO remove
    family = "kcp"
    network_mode = "awsvpc"
    requires_compatibilities = ["FARGATE"]
    cpu = "${var.kcp_fargate_cpu["${module.global_variables.env}"]}"
    memory = "${var.kcp_fargate_memory["${module.global_variables.env}"]}"
    execution_role_arn = "${aws_iam_role.kcp_esc_task_execution_role.arn}"
    container_definitions = <<DEFINITION
[
  {   
    "essential": true,
    "image": "nginx:latest",
    "name": "kcp-http-proxy-${module.global_variables.env}",
    "networkMode": "awsvpc",
    "portMappings": [
      {
        "protocol": "tcp",
        "containerPort": ${var.kcp_fargate_container_port},
        "hostPort": ${var.kcp_fargate_container_port}
      }
    ],
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-group": "/fargate/service/kcp-${module.global_variables.env}",
        "awslogs-region": "${var.region}",
        "awslogs-stream-prefix": "ecs"
      }
    }
  }
]
DEFINITION
}

resource "aws_ecs_service" "kcp" {#TODO remove
    name = "kcp-${module.global_variables.env}"
    cluster = "${aws_ecs_cluster.kcp.id}"
    task_definition = "${aws_ecs_task_definition.kcp.arn}"
    desired_count = "${module.global_variables.is_prod ? 3 : 1}"
    launch_type = "FARGATE"

    network_configuration {
      security_groups = [
        "${aws_vpc.vpc.default_security_group_id}",
        "${aws_security_group.kcp.id}"
      ]
      subnets = [
        "${aws_subnet.private_2a.id}",
        "${aws_subnet.private_2c.id}",
        "${aws_subnet.public_2a.id}",
        "${aws_subnet.public_2c.id}"
      ]
      assign_public_ip = true
    }

    load_balancer = [{
      target_group_arn = "${aws_alb_target_group.kcp.id}"
      container_name = "kcp-http-proxy-${module.global_variables.env}"
      container_port = "${var.kcp_fargate_container_port}"
    }]

    service_registries {
      registry_arn = "${aws_service_discovery_service.kcp.arn}"
    }

    lifecycle {
      ignore_changes = ["task_definition"]
    }
}

# Service Discovery
resource "aws_service_discovery_private_dns_namespace" "kcp" {
  name = "kcp.local"
  description = "kcp"
  vpc = "${aws_vpc.vpc.id}"
}

resource "aws_service_discovery_service" "kcp" {
  name = "${module.global_variables.env}"
  
  dns_config {
    namespace_id = "${aws_service_discovery_private_dns_namespace.kcp.id}"

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
  threshold = "${var.ecs_as_cpu_high_threshold_per}"

  dimensions {
    ClusterName = "${aws_ecs_cluster.kcp.name}"
    ServiceName = "${aws_ecs_service.kcp.name}"
  }

  alarm_actions = ["${aws_appautoscaling_policy.kcp_scale_up.arn}"]
}

resource "aws_cloudwatch_metric_alarm" "kcp_cpu_low" {
  alarm_name = "kcp-${module.global_variables.env}-cpu-low-${var.ecs_as_cpu_low_threshold_per}"
  comparison_operator = "LessThanThreshold"
  evaluation_periods = "1"
  metric_name = "CPUUtilization"
  namespace = "AWS/ECS"
  period = "60"
  statistic = "Average"
  threshold = "${var.ecs_as_cpu_low_threshold_per}"

  dimensions {
    ClusterName = "${aws_ecs_cluster.kcp.name}"
    ServiceName = "${aws_ecs_service.kcp.name}"
  }

  alarm_actions = ["${aws_appautoscaling_policy.kcp_scale_down.arn}"]
}

resource "aws_appautoscaling_target" "kcp_scale_target" {
  service_namespace = "ecs"
  resource_id = "service/${aws_ecs_cluster.kcp.name}/${aws_ecs_service.kcp.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  max_capacity = "${module.global_variables.is_prod ? "3" : "1"}"
  min_capacity = "1"
}

resource "aws_appautoscaling_policy" "kcp_scale_up" {
  name = "kcp-scale-up"
  service_namespace = "${aws_appautoscaling_target.kcp_scale_target.service_namespace}"
  resource_id = "${aws_appautoscaling_target.kcp_scale_target.resource_id}"
  scalable_dimension = "${aws_appautoscaling_target.kcp_scale_target.scalable_dimension}"

  step_scaling_policy_configuration {
    adjustment_type = "ChangeInCapacity"
    cooldown = 60
    metric_aggregation_type = "Average"

    step_adjustment {
      metric_interval_lower_bound = 0
      scaling_adjustment          = 1
    }
  }

  depends_on = [
    "aws_appautoscaling_target.kcp_scale_target"
  ]
}

resource "aws_appautoscaling_policy" "kcp_scale_down" {
  name = "app-scale-down"
  service_namespace = "${aws_appautoscaling_target.kcp_scale_target.service_namespace}"
  resource_id = "${aws_appautoscaling_target.kcp_scale_target.resource_id}"
  scalable_dimension = "${aws_appautoscaling_target.kcp_scale_target.scalable_dimension}"

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
    "aws_appautoscaling_target.kcp_scale_target"
  ]
}

# CloudWatch
resource "aws_cloudwatch_log_group" "kcp_logs" {
  name = "/fargate/service/kcp-${module.global_variables.env}"
  tags {
    Environment = "${module.global_variables.env}"
  }
}

# Security Groups
resource "aws_security_group" "kcp" {
  vpc_id = "${aws_vpc.vpc.id}"
  name = "kcp-${module.global_variables.env}-security-group"

  ingress {
    from_port = "${var.kcp_fargate_container_port}"
    to_port = "${var.kcp_fargate_container_port}"
    protocol = "TCP"
    cidr_blocks = [
      "${aws_vpc.vpc.cidr_block}",
      "218.232.41.2/32",
      "218.232.41.3/32",
      "218.232.41.4/32",
      "218.232.41.5/32",
      "222.231.4.164/32",
      "222.231.4.165/32"
    ]
  }
  
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = [
      "${aws_vpc.vpc.cidr_block}",
      "218.232.41.2/32",
      "218.232.41.3/32",
      "218.232.41.4/32",
      "218.232.41.5/32",
      "222.231.4.164/32",
      "222.231.4.165/32"
    ]
  }

  tags {
    Name = "kcp-${module.global_variables.env}"
  }
}

# DynamoDB
resource "aws_dynamodb_table" "kcp_approvals" {
  count = "${module.global_variables.is_prod ? 1 : 0}"
  name = "${var.kcp_dynamodb_table_name}"
  billing_mode = "PROVISIONED"
  read_capacity = "${module.global_variables.is_prod ? 3 : 1}"
  write_capacity = "${module.global_variables.is_prod ? 3 : 1}"
  hash_key = "id"

  attribute {
    name = "id"
    type = "S"
  }

  tags = {
    Name = "${var.kcp_dynamodb_table_name}"
    Environmet = "${module.global_variables.env}"
  }
}
