locals {
  frontend_s3_origin_id = "ridi-pay-origin-${module.global_variables.env}"
}

resource "aws_s3_bucket" "ridi_pay_frontend" {
  bucket = "ridi-pay-frontend-${module.global_variables.env}"
}

resource "aws_cloudfront_origin_access_identity" "ridi_pay_frontend" {}

resource "aws_cloudfront_distribution" "ridi_pay_frontend" {
  default_root_object = "index.html"
  enabled = true
  is_ipv6_enabled = true

  aliases = [
    "${module.global_variables.env == "prod" ? "pay.ridibooks.com" : "${module.global_variables.env}.pay.ridibooks.com"}",
  ]

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
    acm_certificate_arn = "${data.aws_acm_certificate.cert-us-east-1.arn}"
    minimum_protocol_version = "TLSv1.1_2016"
    ssl_support_method = "sni-only"
  }

  # Workaround for resource count https://github.com/hashicorp/terraform/issues/16681#issuecomment-345105956
  web_acl_id = "${module.global_variables.is_prod ? "" : element(concat(aws_waf_web_acl.ridi_pay_frontend.*.id, list("")), 0)}"
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
  count = "${module.global_variables.is_prod ? 0 : 1}"

  ip_set_descriptors {
    type  = "IPV4"
    value = "218.232.41.2/32"
  }
  ip_set_descriptors {
    type  = "IPV4"
    value = "218.232.41.3/32"
  }
  ip_set_descriptors {
    type  = "IPV4"
    value = "218.232.41.4/32"
  }
  ip_set_descriptors {
    type  = "IPV4"
    value = "218.232.41.5/32"
  }
  ip_set_descriptors {
    type  = "IPV4"
    value = "222.231.4.164/32"
  }
  ip_set_descriptors {
    type  = "IPV4"
    value = "222.231.4.165/32"
  }
}

resource "aws_waf_rule" "ridi_pay_frontend" {
  depends_on  = ["aws_waf_ipset.ridi_pay_frontend"]
  name        = "RidiPayWAFRule"
  metric_name = "RidiPayWAFRule"
  count = "${module.global_variables.is_prod ? 0 : 1}"

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
  count = "${module.global_variables.is_prod ? 0 : 1}"

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