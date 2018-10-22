output "env" {
  value = "${terraform.workspace == "default" ? "prod" : "${terraform.workspace}"}"
}

output "is_staging" {
  value = "${terraform.workspace == "staging"}"
}