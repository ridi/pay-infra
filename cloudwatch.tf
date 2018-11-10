resource "aws_cloudwatch_log_group" "backend_api_apache_access" {
  name = "${module.global_variables.env}.ridi-pay.backend.api.apache.access"

  tags {
    Environment = "${module.global_variables.env}"
  }
}

resource "aws_cloudwatch_log_group" "backend_api_apache_error" {
  name = "${module.global_variables.env}.ridi-pay.backend.api.apache.error"

  tags {
    Environment = "${module.global_variables.env}"
  }
}

resource "aws_cloudwatch_log_group" "backend_api_pg_kcp" {
  name = "${module.global_variables.env}.ridi-pay.backend.api.pg.kcp"

  tags {
    Environment = "${module.global_variables.env}"
  }
}
