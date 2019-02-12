resource "aws_ecr_repository" "ridi_pay_backend" {
  count = "${module.global_variables.is_prod ? 1 : 0}"
  name = "ridi/pay-backend"
}

resource "aws_ecr_repository" "ridi_pay_backend_fluentd" {
  count = "${module.global_variables.is_prod ? 1 : 0}"
  name = "ridi/pay-backend-fluentd"
}

resource "aws_ecs_cluster" "ridi_pay_backend" {
  name = "ridi-pay-backend-${module.global_variables.env}"
}

resource "aws_launch_configuration" "ridi_pay_backend" {
  name_prefix = "ridi-pay-backend-ecs-"
  image_id = "${data.aws_ami.amazon_ecs_optimized.id}"
  instance_type = "${module.global_variables.is_prod ? "t3.medium" : "t3.micro"}"
  iam_instance_profile = "ecsInstanceRole"
  key_name = "${var.key_pair["${module.global_variables.env}"]}"
  security_groups = [
    "${aws_vpc.vpc.default_security_group_id}",
    "${aws_security_group.ssh_from_bastion.id}"
  ]
  user_data = <<EOF
#!/bin/bash
echo ECS_CLUSTER=${aws_ecs_cluster.ridi_pay_backend.name} >> /etc/ecs/ecs.config
echo ECS_AVAILABLE_LOGGING_DRIVERS=[\"json-file\",\"syslog\",\"awslogs\",\"fluentd\",\"none\"] >> /etc/ecs/ecs.config
EOF
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_launch_configuration" "ridi_pay_backend_fluentd" {
  name_prefix = "ridi-pay-backend-fluentd-ecs-"
  image_id = "${data.aws_ami.amazon_ecs_optimized.id}"
  instance_type = "${module.global_variables.is_prod ? "t3.medium" : "t3.micro"}"
  iam_instance_profile = "ecsInstanceRole"
  key_name = "${var.key_pair["${module.global_variables.env}"]}"
  security_groups = [
    "${aws_vpc.vpc.default_security_group_id}",
    "${aws_security_group.ssh_from_bastion.id}"
  ]
  user_data = <<EOF
#!/bin/bash
echo ECS_CLUSTER=${aws_ecs_cluster.ridi_pay_backend.name} >> /etc/ecs/ecs.config
echo ECS_INSTANCE_ATTRIBUTES={\"service\":\"fluentd\"} >> /etc/ecs/ecs.config
EOF
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "ridi_pay_backend" {
  max_size = "${module.global_variables.is_prod ? 4 : 1}"
  min_size = "${module.global_variables.is_prod ? 2 : 1}"
  desired_capacity = "${module.global_variables.is_prod ? 2 : 1}"
  availability_zones = [
    "ap-northeast-2a",
    "ap-northeast-2c"
  ]
  launch_configuration = "${aws_launch_configuration.ridi_pay_backend.name}"
  vpc_zone_identifier = [
    "${aws_subnet.private_2a.id}",
    "${aws_subnet.private_2c.id}"
  ]
  tag {
    key = "Name"
    value = "${aws_launch_configuration.ridi_pay_backend.name}"
    propagate_at_launch = true
  }
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "ridi_pay_backend_fluentd" {
  max_size = "${module.global_variables.is_prod ? 4 : 1}"
  min_size = "${module.global_variables.is_prod ? 2 : 1}"
  desired_capacity = "${module.global_variables.is_prod ? 2 : 1}"
  availability_zones = [
    "ap-northeast-2a",
    "ap-northeast-2c"
  ]
  launch_configuration = "${aws_launch_configuration.ridi_pay_backend_fluentd.name}"
  vpc_zone_identifier = [
    "${aws_subnet.private_2a.id}",
    "${aws_subnet.private_2c.id}"
  ]
  tag {
    key = "Name"
    value = "${aws_launch_configuration.ridi_pay_backend_fluentd.name}"
    propagate_at_launch = true
  }
  lifecycle {
    create_before_destroy = true
  }
}
