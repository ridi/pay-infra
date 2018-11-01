resource "aws_s3_bucket" "ridi_pay_frontend" {
  bucket = "ridi-pay-frontend-${module.global_variables.env}"
}

resource "aws_s3_bucket_policy" "ridi_pay_frontend" {
  bucket = "${aws_s3_bucket.ridi_pay_frontend.id}"
  policy = "${data.aws_iam_policy_document.ridi_pay_frontend.json}"
}
