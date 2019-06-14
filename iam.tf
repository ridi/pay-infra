data "aws_iam_policy_document" "ridi_pay_frontend" {
  statement {
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.ridi_pay_frontend.arn}/*"]

    principals {
      type        = "AWS"
      identifiers = [aws_cloudfront_origin_access_identity.ridi_pay_frontend.iam_arn]
    }
  }

  # CloudFront cannot determine whether a requested resource exists in
  # S3 bucket unless it has ListBucket permission.
  statement {
    actions   = ["s3:ListBucket"]
    resources = [aws_s3_bucket.ridi_pay_frontend.arn]

    principals {
      type        = "AWS"
      identifiers = [aws_cloudfront_origin_access_identity.ridi_pay_frontend.iam_arn]
    }
  }
}

