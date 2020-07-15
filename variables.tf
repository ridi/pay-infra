variable "region" {
  default = "ap-northeast-2"
}

variable "acm_certificate_domain_frontend" {
  default = {
    "prod"    = "pay.ridibooks.com"
    "staging" = "pay.ridibooks.com"
    "test"    = "pay.ridi.io"
  }
}

variable "acm_certificate_domain_backend" {
  default = {
    "prod"    = "pay-api.ridibooks.com"
    "staging" = "pay-api.ridibooks.com"
    "test"    = "pay-api.dev.ridi.io"
  }
}

variable "vpc_cidr_blocks" {
  default = {
    "prod"    = "10.0.0.0/16"
    "staging" = "10.10.0.0/16"
    "test"    = "10.20.0.0/16"
  }
}

variable "public_2a_cidr_blocks" {
  default = {
    "prod"    = "10.0.0.0/24"
    "staging" = "10.10.0.0/24"
    "test"    = "10.20.0.0/24"
  }
}

variable "public_2c_cidr_blocks" {
  default = {
    "prod"    = "10.0.1.0/24"
    "staging" = "10.10.1.0/24"
    "test"    = "10.20.1.0/24"
  }
}

variable "private_2a_cidr_blocks" {
  default = {
    "prod"    = "10.0.10.0/24"
    "staging" = "10.10.10.0/24"
    "test"    = "10.20.10.0/24"
  }
}

variable "private_2c_cidr_blocks" {
  default = {
    "prod"    = "10.0.11.0/24"
    "staging" = "10.10.11.0/24"
    "test"    = "10.20.11.0/24"
  }
}

variable "bastion_key_pair" {
  default = {
    "prod"    = "bastion-prod"
    "staging" = "bastion-staging"
    "test"    = "bastion-test"
  }
}

variable "frontend_cf_alias" {
  default = {
    "prod"    = "pay.ridibooks.com"
    "staging" = "staging.pay.ridibooks.com"
    "test"    = "pay.ridi.io"
  }
}

variable "office_cidr_blocks" {
  default = [
    "218.232.41.2/32",
    "218.232.41.3/32",
    "218.232.41.4/32",
    "218.232.41.5/32",
    "222.231.4.164/32",
    "222.231.4.165/32",
  ]
}

variable "bastion_internal_outbound_ports" {
  default = [
    22,
    80,
    443,
    6379,
    3306
  ]
}