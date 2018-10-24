resource "aws_alb" "alb" {
  internal = false
  load_balancer_type = "application"
  name = "ridi-pay-${module.global_variables.env}"
  security_groups = [
    "${aws_security_group.alb_http.id}",
    "${aws_security_group.alb_https.id}",
    "${aws_security_group.store.id}"
  ]
  subnets = [
    "${aws_subnet.public_2a.id}",
    "${aws_subnet.public_2c.id}"
  ]
  lifecycle {
    create_before_destroy = true
  }
  tags {
    Environment = "${module.global_variables.env}"
  }
}

resource "aws_alb_target_group" "alb_target_group" {
  port = 80
  protocol = "HTTP"
  vpc_id = "${aws_vpc.vpc.id}"
  depends_on = [
    "aws_alb.alb"
  ]
}

resource "aws_alb_listener" "alb_listener" {
  load_balancer_arn = "${aws_alb.alb.arn}"
  port = 443
  protocol = "HTTPS"
  ssl_policy = "ELBSecurityPolicy-2016-08"
  certificate_arn = "${data.aws_acm_certificate.cert.arn}"
  default_action {
    type = "forward"
    target_group_arn = "${aws_alb_target_group.alb_target_group.arn}"
  }
}
