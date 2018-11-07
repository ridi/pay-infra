resource "aws_s3_bucket" "ridi_pay_frontend" {
  bucket = "ridi-pay-frontend-${module.global_variables.env}"
}

resource "aws_s3_bucket_policy" "ridi_pay_frontend" {
  bucket = "${aws_s3_bucket.ridi_pay_frontend.id}"
  policy = "${data.aws_iam_policy_document.ridi_pay_frontend.json}"
}

resource "aws_s3_bucket" "ridi_pay_backend_api_doc" {
  count = "${module.global_variables.is_prod ? 1 : 0}"
  bucket = "ridi-pay-backend-api-doc"
}

resource "aws_s3_bucket_policy" "ridi_pay_backend_api_doc" {
  count = "${module.global_variables.is_prod ? 1 : 0}"
  bucket = "${aws_s3_bucket.ridi_pay_backend_api_doc.id}"
  policy = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": "*",
            "Action": "s3:GetObject",
            "Resource": "arn:aws:s3:::ridi-pay-backend-api-doc/*",
            "Condition": {
                "IpAddress": {
                    "aws:SourceIp": [
                      "218.232.41.2/32",
                      "218.232.41.3/32",
                      "218.232.41.4/32",
                      "218.232.41.5/32",
                      "222.231.4.164/32",
                      "222.231.4.165/32"
                    ]
                }
            }
        }
    ]
}
POLICY
}
