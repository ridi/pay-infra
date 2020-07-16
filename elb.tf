resource "aws_alb" "ridi_pay_backend_fargate" {
  internal           = false
  load_balancer_type = "application"
  name               = "pay-backend-${module.global_variables.env}"
  security_groups = [
    aws_security_group.web.id,
  ]
  subnets = [
    aws_subnet.public_2a.id,
    aws_subnet.public_2c.id,
  ]
  enable_deletion_protection = true
  lifecycle {
    create_before_destroy = true
  }
  tags = {
    Environment = module.global_variables.env
  }
}

resource "aws_alb_target_group" "ridi_pay_backend_fargate" {
  port                 = 80
  protocol             = "HTTP"
  target_type          = "ip"
  vpc_id               = aws_vpc.vpc.id
  deregistration_delay = 60
  depends_on           = [aws_alb.ridi_pay_backend_fargate]
  health_check {
    path    = "/health-check"
    matcher = "200"
  }
}

resource "aws_alb_listener" "ridi_pay_backend_fargate" {
  load_balancer_arn = aws_alb.ridi_pay_backend_fargate.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS-1-1-2017-01"
  certificate_arn   = data.aws_acm_certificate.cert.arn
  default_action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.ridi_pay_backend_fargate.arn
  }
}
