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

resource "aws_iam_user" "hoseongson" {
  name = "hoseong.son"
}

resource "aws_iam_user_policy_attachment" "hoseongson_readonly" {
  user       = aws_iam_user.hoseongson.name
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}

resource "aws_iam_user_policy_attachment" "hoseongson_iam_change_password" {
  user       = aws_iam_user.hoseongson.name
  policy_arn = "arn:aws:iam::aws:policy/IAMUserChangePassword"
}
