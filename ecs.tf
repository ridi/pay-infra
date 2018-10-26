resource "aws_ecr_repository" "ridi_pay" {
  count = "${module.global_variables.is_prod ? 1 : 0}"
  name = "ridi/pay"
}

resource "aws_ecs_cluster" "ridi_pay" {
  name = "ridi-pay-${module.global_variables.env}"
}

resource "aws_launch_configuration" "ecs_launch_configuration" {
  name_prefix = "ridi-pay-ecs-"
  image_id = "${data.aws_ami.amazon_ecs_optimized.id}"
  instance_type = "t2.micro"
  iam_instance_profile = "ecsInstanceRole"
  key_name = "bastion"
  security_groups = [
    "${aws_vpc.vpc.default_security_group_id}",
    "${aws_security_group.ssh_from_bastion.id}"
  ]
  user_data = <<EOF
#!/bin/bash
echo ECS_CLUSTER=${aws_ecs_cluster.ridi_pay.name} >> /etc/ecs/ecs.config
EOF
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "ecs_autoscaling_group" {
  max_size = 1
  min_size = 1
  desired_capacity = 1
  availability_zones = ["ap-northeast-2a", "ap-northeast-2c"]
  launch_configuration = "${aws_launch_configuration.ecs_launch_configuration.name}"
  vpc_zone_identifier = [
    "${aws_subnet.private_2a.id}",
    "${aws_subnet.private_2c.id}"
  ]
  tag {
    key = "Name"
    value = "${aws_launch_configuration.ecs_launch_configuration.name}"
    propagate_at_launch = true
  }
  lifecycle {
    create_before_destroy = true
  }
}
