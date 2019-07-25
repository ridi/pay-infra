variable "dynamodb_table_name_kcp_payment_approval_requests" {
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

resource "aws_dynamodb_table" "kcp_payment_approval_requests" {
  name = "${var.dynamodb_table_name_kcp_payment_approval_requests}-${module.global_variables.env}"
  billing_mode = "PAY_PER_REQUEST"
  hash_key = "id"

  attribute {
    name = "id"
    type = "S"
  }

  ttl {
    attribute_name = "ttl"
    enabled = true
  }

  tags = {
    Name = var.dynamodb_table_name_kcp_payment_approval_requests
    Environment = module.global_variables.env
  }
}
