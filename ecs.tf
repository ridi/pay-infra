resource "aws_ecr_repository" "ridi_pay" {
  count = "${module.global_variables.is_prod ? 1 : 0}"
  name = "ridi/pay"
}

resource "aws_ecs_cluster" "ridi_pay" {
  name = "ridi-pay-${module.global_variables.env}"
}

resource "aws_ecs_service" "api" {
  name = "api"
  cluster = "${aws_ecs_cluster.ridi_pay.id}"
  task_definition = "${aws_ecs_task_definition.api.arn}"
  desired_count = 1
  load_balancer {
    target_group_arn = "${aws_alb_target_group.alb_target_group.arn}"
    container_name = "api"
    container_port = 80
  }
}

resource "aws_ecs_task_definition" "api" {
  family = "api"
  container_definitions = <<DEFINITION
[
  {
    "name": "api",
    "image": "023315198496.dkr.ecr.ap-northeast-2.amazonaws.com/ridi/pay",
    "memory": 256,
    "essential": true,
    "portMappings": [
      {
        "containerPort": 80,
        "hostPort": 80
      }
    ]
  }
]
DEFINITION
  task_role_arn = "${aws_iam_role.ecs_tasks_trust_role.arn}"
}

resource "aws_launch_configuration" "ecs_launch_configuration" {
  image_id = "${data.aws_ami.amazon_ecs_optimized.id}"
  instance_type = "t2.micro"
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "ecs_autoscaling_group" {
  max_size = 1
  min_size = 1
  desired_capacity = 1
  launch_configuration = "${aws_launch_configuration.ecs_launch_configuration.name}"
  vpc_zone_identifier = [
    "${aws_subnet.private_2a.id}",
    "${aws_subnet.private_2c.id}"
  ]
}
