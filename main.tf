terraform {
  backend "s3" {
    bucket         = "ridi-pay-terraform-state"
    dynamodb_table = "terraform-state-lock"
    region         = "ap-northeast-2"
    key            = "terraform.tfstate"
  }
}

provider "aws" {
  region = "${var.region}"
}

resource "aws_s3_bucket" "terraform_state" {
  bucket = "ridi-pay-terraform-state"
  versioning {
    enabled = true
  }
}

resource "aws_dynamodb_table" "terraform_state_lock" {
  name           = "terraform-state-lock"
  read_capacity  = 20
  write_capacity = 20
  hash_key       = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}

resource "aws_s3_bucket" "ridi_pay_frontend_bucket" {
  bucket = "${var.prefix}pay.ridibooks.com"
}
