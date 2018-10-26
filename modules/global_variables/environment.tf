output "env" {
  value = "${terraform.workspace == "default" ? "prod" : "${terraform.workspace}"}"
}

output "is_prod" {
  value = "${terraform.workspace == "default"}"
}

output "is_staging" {
  value = "${terraform.workspace == "staging"}"
}

output "is_test" {
  value = "${terraform.workspace == "test"}"
}