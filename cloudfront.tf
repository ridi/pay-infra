data "aws_iam_role" "lambda_at_edge" {
  name = "lambda-at-edge"
}

resource "aws_lambda_function" "ridi_pay_frontend_lambda" {
  provider      = "aws.us-east-1"
  description   = "Blueprint for modifying CloudFront response header implemented in NodeJS."
  function_name = "ridi-pay-frontend-${module.global_variables.env}"
  handler       = "index.handler"
  role          = "${data.aws_iam_role.lambda_at_edge.arn}"
  runtime       = "nodejs8.10"
  timeout       = 1

  tags {
    "lambda-console:blueprint" = "cloudfront-modify-response-header"
  }
}

resource "aws_cloudfront_distribution" "ridi_pay_frontend" {
  default_root_object = "index.html"
  enabled = true
  is_ipv6_enabled = true

  aliases = [
    "${var.frontend_cf_alias[module.global_variables.env]}"
  ]

  custom_error_response {
    error_code = 404
    response_code = 200
    error_caching_min_ttl = 0
    response_page_path = "/index.html"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  origin {
    domain_name = "${aws_s3_bucket.ridi_pay_frontend.bucket_domain_name}"
    origin_id = "${module.global_variables.frontend_s3_origin_id}"

    s3_origin_config {
      origin_access_identity = "${aws_cloudfront_origin_access_identity.ridi_pay_frontend.cloudfront_access_identity_path}"
    }
  }

  default_cache_behavior {
    allowed_methods = ["GET", "HEAD"]
    cached_methods = ["GET", "HEAD"]
    compress = true
    default_ttl = 0
    max_ttl = 31536000 
    min_ttl = 0
    target_origin_id = "${module.global_variables.frontend_s3_origin_id}"
    viewer_protocol_policy = "redirect-to-https"

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    lambda_function_association {
      event_type   = "origin-response"
      lambda_arn   = "${aws_lambda_function.ridi_pay_frontend_lambda.qualified_arn}"
      include_body = false
    }
  }

  viewer_certificate {
    acm_certificate_arn = "${data.aws_acm_certificate.cert-us-east-1.arn}"
    minimum_protocol_version = "TLSv1.1_2016"
    ssl_support_method = "sni-only"
  }

  # Workaround for resource count https://github.com/hashicorp/terraform/issues/16681#issuecomment-345105956
  # web_acl_id = "${module.global_variables.is_prod ? "" : element(concat(aws_waf_web_acl.ridi_pay_frontend.*.id, list("")), 0)}"
  web_acl_id = "${aws_waf_web_acl.ridi_pay_frontend.id}"
}

resource "aws_cloudfront_origin_access_identity" "ridi_pay_frontend" {}
