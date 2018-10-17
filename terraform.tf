terraform {
  backend "s3" {
    bucket         = "ridi-pay-terraform-state"
    dynamodb_table = "terraform-state-lock"
    region         = "ap-northeast-2"
    key            = "terraform.tfstate"
  }
}