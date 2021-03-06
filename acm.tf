data "aws_acm_certificate" "cert" {
  domain = var.acm_certificate_domain_backend[module.global_variables.env]
}

data "aws_acm_certificate" "cert-us-east-1" {
  domain   = var.acm_certificate_domain_frontend[module.global_variables.env]
  provider = aws.us-east-1
}

