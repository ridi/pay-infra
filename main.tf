locals {
  env = "${terraform.workspace == "default" ? "prod" : "${terraform.workspace}"}"
  is_staging = "${local.env == "staging"}"
  frontend_s3_origin_id = "ridi-pay-origin-${local.env}"
}

resource "aws_s3_bucket" "ridi_pay_frontend" {
  bucket = "ridi-pay-frontend-${local.env}"
}

resource "aws_cloudfront_origin_access_identity" "ridi_pay_frontend" {}

resource "aws_cloudfront_distribution" "ridi_pay_frontend" {
  default_root_object = "index.html"
  enabled = true
  is_ipv6_enabled = true

  aliases = [
    "${local.env == "default" ? "pay.ridibooks.com" : "${local.env}-pay.ridibooks.com"}",
  ]

  custom_error_response {
    error_caching_min_ttl = 300
    error_code = 403
    response_code = 200
    response_page_path = "/index.html"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  origin {
    domain_name = "${aws_s3_bucket.ridi_pay_frontend.bucket_domain_name}"
    origin_id = "${local.frontend_s3_origin_id}"

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
    target_origin_id = "${local.frontend_s3_origin_id}"
    viewer_protocol_policy = "redirect-to-https"

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
    minimum_protocol_version = "TLSv1.1_2016"
    ssl_support_method = "sni-only"
  }

  # Workaround for resource count https://github.com/hashicorp/terraform/issues/16681#issuecomment-345105956
  web_acl_id = "${local.is_staging ? element(concat(aws_waf_web_acl.ridi_pay_frontend.*.id, list("")), 0) : ""}"
}

data "aws_iam_policy_document" "ridi_pay_frontend" {
  statement {
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.ridi_pay_frontend.arn}/*"]

    principals {
      type        = "AWS"
      identifiers = ["${aws_cloudfront_origin_access_identity.ridi_pay_frontend.iam_arn}"]
    }
  }
}

resource "aws_s3_bucket_policy" "ridi_pay_frontend" {
  bucket = "${aws_s3_bucket.ridi_pay_frontend.id}"
  policy = "${data.aws_iam_policy_document.ridi_pay_frontend.json}"
}

resource "aws_waf_ipset" "ridi_pay_frontend" {
  name = "RidiPayIPSet"
  count = "${local.is_staging ? 1 : 0}"

  ip_set_descriptors {
    type  = "IPV4"
    value = "218.232.41.2/24"
  }
  ip_set_descriptors {
    type  = "IPV4"
    value = "218.232.41.3/24"
  }
  ip_set_descriptors {
    type  = "IPV4"
    value = "218.232.41.4/24"
  }
  ip_set_descriptors {
    type  = "IPV4"
    value = "218.232.41.5/24"
  }
}

resource "aws_waf_rule" "ridi_pay_frontend" {
  depends_on  = ["aws_waf_ipset.ridi_pay_frontend"]
  name        = "RidiPayWAFRule"
  metric_name = "RidiPayWAFRule"
  count = "${local.is_staging ? 1 : 0}"

  predicates {
    data_id = "${aws_waf_ipset.ridi_pay_frontend.id}"
    negated = false
    type    = "IPMatch"
  }
}

resource "aws_waf_web_acl" "ridi_pay_frontend" {
  depends_on  = ["aws_waf_ipset.ridi_pay_frontend", "aws_waf_rule.ridi_pay_frontend"]
  name        = "RidiPayWebACL"
  metric_name = "RidiPayWebACL"
  count = "${local.is_staging ? 1 : 0}"

  default_action {
    type = "BLOCK"
  }

  rules {
    action {
      type = "ALLOW"
    }

    priority = 1
    rule_id  = "${aws_waf_rule.ridi_pay_frontend.id}"
    type     = "REGULAR"
  }
}