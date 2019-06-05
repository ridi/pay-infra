locals {
  env = terraform.workspace
}

output "env" {
  value = local.env
}

output "is_prod" {
  value = terraform.workspace == "prod"
}

output "is_staging" {
  value = terraform.workspace == "staging"
}

output "is_test" {
  value = terraform.workspace == "test"
}

output "frontend_s3_origin_id" {
  value = "ridi-pay-origin-${local.env}"
}
