output "env" {
  value = "${terraform.workspace == "default" ? "prod" : "${terraform.workspace}"}"
}

output "is_prod" {
  value = "${terraform.workspace == "default"}"
}