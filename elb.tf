resource "aws_alb" "ridi_pay_backend" {
  internal = false
  load_balancer_type = "application"
  name = "ridi-pay-backend-${module.global_variables.env}"
  security_groups = [
    "${aws_security_group.web.id}"
  ]
  subnets = [
    "${aws_subnet.public_2a.id}",
    "${aws_subnet.public_2c.id}"
  ]
  enable_deletion_protection = true
  lifecycle {
    create_before_destroy = true
  }
  tags {
    Environment = "${module.global_variables.env}"
  }
}

resource "aws_lb" "ridi_pay_backend_fluentd" {
  internal = true
  load_balancer_type = "network"
  name = "ridi-pay-backend-fluentd-${module.global_variables.env}"
  subnets = [
    "${aws_subnet.private_2a.id}",
    "${aws_subnet.private_2c.id}"
  ]
  enable_deletion_protection = true
  lifecycle {
    create_before_destroy = true
  }
  tags {
    Environment = "${module.global_variables.env}"
  }
}

resource "aws_alb_target_group" "ridi_pay_backend" {
  port = 80
  protocol = "HTTP"
  vpc_id = "${aws_vpc.vpc.id}"
  deregistration_delay = 60
  depends_on = [
    "aws_alb.ridi_pay_backend"
  ]
  health_check {
    path = "/health-check"
    matcher = "200"
  }
}

resource "aws_lb_target_group" "ridi_pay_backend_fluentd" {
  port = 24224
  protocol = "TCP"
  vpc_id = "${aws_vpc.vpc.id}"
  deregistration_delay = 60
  depends_on = [
    "aws_lb.ridi_pay_backend_fluentd"
  ]
}

resource "aws_alb_listener" "ridi_pay_backend" {
  load_balancer_arn = "${aws_alb.ridi_pay_backend.arn}"
  port = 443
  protocol = "HTTPS"
  ssl_policy = "ELBSecurityPolicy-2016-08"
  certificate_arn = "${data.aws_acm_certificate.cert.arn}"
  default_action {
    type = "forward"
    target_group_arn = "${aws_alb_target_group.ridi_pay_backend.arn}"
  }
}

resource "aws_lb_listener" "ridi_pay_backend_fluentd" {
  load_balancer_arn = "${aws_lb.ridi_pay_backend_fluentd.arn}"
  port = 24224
  protocol = "TCP"
  default_action {
    type = "forward"
    target_group_arn = "${aws_lb_target_group.ridi_pay_backend_fluentd.arn}"
  }
}
