resource "aws_s3_bucket" "ridi_pay_frontend" {
  bucket = "ridi-pay-frontend-${module.global_variables.env}"
}

resource "aws_s3_bucket_policy" "ridi_pay_frontend" {
  bucket = aws_s3_bucket.ridi_pay_frontend.id
  policy = data.aws_iam_policy_document.ridi_pay_frontend.json
}

resource "aws_s3_bucket" "ridi_pay_backend_api_doc" {
  count  = module.global_variables.is_prod ? 1 : 0
  bucket = "ridi-pay-backend-api-doc"

  logging {
    target_bucket = aws_s3_bucket.ridi_pay_access_logs[0].id
    target_prefix = "s3/ridi-pay-backend-api-doc/"
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
}

resource "aws_s3_bucket_policy" "ridi_pay_backend_api_doc" {
  count  = module.global_variables.is_prod ? 1 : 0
  bucket = aws_s3_bucket.ridi_pay_backend_api_doc[0].id
  policy = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": "*",
            "Action": "s3:GetObject",
            "Resource": "arn:aws:s3:::ridi-pay-backend-api-doc/*"
        }
    ]
}
POLICY

}

resource "aws_s3_bucket" "ridi_pay_access_logs" {
  count  = module.global_variables.is_prod ? 1 : 0
  region = "ap-northeast-2"
  bucket = "ridi-pay-access-logs"
  acl    = "log-delivery-write"
}
