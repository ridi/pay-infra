terraform {
  backend "remote" {
    hostname = "app.terraform.io"
    organization = "ridi"

    workspaces {
      prefix = "pay-"
    }
  }
}

provider "aws" {
  region = "${var.region}"
}

provider "aws" {
  alias = "us-east-1"
  region = "us-east-1"
}
