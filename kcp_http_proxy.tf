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

resource "aws_lb" "kcp_http_proxy" {
  name = "kcp-http-proxy-${module.global_variables.env}"
  internal = true
  load_balancer_type = "application"
  security_groups = [aws_security_group.kcp_http_proxy.id]
  subnets = [
    aws_subnet.public_2a.id,
    aws_subnet.public_2c.id,
  ]

  enable_deletion_protection = true

  tags = {
    Environment = module.global_variables.env
  }
}

resource "aws_lb_target_group" "kcp_http_proxy" {
  port = 80
  protocol = "HTTP"
  target_type = "ip"
  vpc_id = aws_vpc.vpc.id
  deregistration_delay = 60
  depends_on = [aws_lb.kcp_http_proxy]
  health_check {
    path = "/health"
    matcher = "200"
  }
}

resource "aws_lb_listener" "kcp_http_proxy" {
  load_balancer_arn = aws_lb.kcp_http_proxy.arn
  port = 80
  protocol = "HTTP"
  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.kcp_http_proxy.arn
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
    protocol = "tcp"
    cidr_blocks = [
      aws_vpc.vpc.cidr_block
    ]
  }
  
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
