resource "aws_ecr_repository" "kcp_http_proxy" {
  name = "ridi/kcp-http-proxy"
  count = module.global_variables.is_prod ? 1 : 0
}
