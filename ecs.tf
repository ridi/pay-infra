resource "aws_ecr_repository" "ridi_pay_backend" {
  count = module.global_variables.is_prod ? 1 : 0
  name  = "ridi/pay-backend"
}

resource "aws_ecs_cluster" "ridi_pay_backend" {
  name = "ridi-pay-backend-${module.global_variables.env}"
  setting {
    name  = "containerInsights"
    value = module.global_variables.is_prod ? "enabled" : "disabled"
  }
}
