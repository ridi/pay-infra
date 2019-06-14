resource "aws_waf_ipset" "ridi_pay_frontend" {
  name  = "RidiPayIPSet"
  count = module.global_variables.is_prod ? 0 : 1

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
  depends_on  = [aws_waf_ipset.ridi_pay_frontend]
  name        = "RidiPayWAFRule"
  metric_name = "RidiPayWAFRule"
  count       = module.global_variables.is_prod ? 0 : 1

  predicates {
    data_id = aws_waf_ipset.ridi_pay_frontend[0].id
    negated = false
    type    = "IPMatch"
  }
}

resource "aws_waf_web_acl" "ridi_pay_frontend" {
  depends_on = [
    aws_waf_ipset.ridi_pay_frontend,
    aws_waf_rule.ridi_pay_frontend,
  ]
  name        = "RidiPayWebACL"
  metric_name = "RidiPayWebACL"
  count       = module.global_variables.is_prod ? 0 : 1

  default_action {
    type = "BLOCK"
  }

  rules {
    action {
      type = "ALLOW"
    }

    priority = 1
    rule_id  = aws_waf_rule.ridi_pay_frontend[0].id
    type     = "REGULAR"
  }
}

