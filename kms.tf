resource "aws_kms_key" "rds" {
}

resource "aws_kms_alias" "rds" {
  name          = "alias/ridi-pay/rds-${module.global_variables.env}"
  target_key_id = aws_kms_key.rds.key_id
}

data "aws_kms_secrets" "rds" {
  secret {
    name    = "password"
    payload = "AQICAHh9EsplE4uLVJhjd+ktDndzMOjj6hwDRJ7aIKHQ96jI7QGCzOdLtOyuqlmMl2ueHCjiAAAAfjB8BgkqhkiG9w0BBwagbzBtAgEAMGgGCSqGSIb3DQEHATAeBglghkgBZQMEAS4wEQQMCULiY+JYXsN6VeR5AgEQgDsSRDagtDYXeuOEFUrGoVPFA2cERbFQAR3oVN3EMcXv8lSU2x0WIZWGgOTZa4iNW1u+pFxNhUerPFJpBQ=="
  }
}

