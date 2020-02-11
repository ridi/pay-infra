resource "aws_kms_key" "rds" {
}

resource "aws_kms_alias" "rds" {
  name          = "alias/ridi-pay/rds-${module.global_variables.env}"
  target_key_id = aws_kms_key.rds.key_id
}

data "aws_kms_secrets" "rds" {
  secret {
    name    = "password_prod"
    payload = "AQICAHhHeYG7tepQjDu3rDQlcLW8TM0CviF3PGdQ0dz4JI4cSQG4E88E6xSLkPIdLCMgONYQAAAAfjB8BgkqhkiG9w0BBwagbzBtAgEAMGgGCSqGSIb3DQEHATAeBglghkgBZQMEAS4wEQQMUBtn0qMvA+FHqsvvAgEQgDsu3nIdCwuOaj4zioJLp3n/pwEJMctWz14hhf/uVJqRRkHV4Fbdl5XuyGQe/Yua+4y2EKp1cUKpwEjGtw=="
  }

  secret {
    name    = "password_test"
    payload = "AQICAHgku3v5dj3brfwlQ/NdPk3BUU8tn3kI60eEkYGp7PkPZgEkciaxwgNqZaYsdPyPSPEsAAAAfjB8BgkqhkiG9w0BBwagbzBtAgEAMGgGCSqGSIb3DQEHATAeBglghkgBZQMEAS4wEQQMwBkUkID0dqJKiRAsAgEQgDvGz4EZoydJWMWHUkw4CVyfe/M6PQPZk5pbhXwYy8+7gMw5gI2iZf9ndLZ3bFJBULKj2uCijZrT3MQgyQ=="
  }
}

