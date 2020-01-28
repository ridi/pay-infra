resource "aws_db_instance" "master" {
  count                      = module.global_variables.is_staging ? 0 : 1
  identifier                 = "ridi-pay-${module.global_variables.env}-master"
  allocated_storage          = module.global_variables.is_prod ? 250 : 16
  storage_type               = "gp2"
  engine                     = "mariadb"
  engine_version             = "10.3.8"
  instance_class             = module.global_variables.is_prod ? "db.t3.medium" : "db.t3.micro"
  name                       = "ridi_pay"
  username                   = "ridi"
  password                   = data.aws_kms_secrets.rds.plaintext["password"]
  multi_az                   = module.global_variables.is_prod ? true : false
  parameter_group_name       = aws_db_parameter_group.master[0].name
  db_subnet_group_name       = aws_db_subnet_group.rds[0].name
  vpc_security_group_ids     = [aws_security_group.rds.id]
  auto_minor_version_upgrade = false
  backup_retention_period    = 7
  ca_cert_identifier         = "rds-ca-2019"
}

resource "aws_db_instance" "slave" {
  count                      = module.global_variables.is_prod ? 1 : 0
  identifier                 = "ridi-pay-${module.global_variables.env}-slave"
  replicate_source_db        = aws_db_instance.master[0].identifier
  allocated_storage          = module.global_variables.is_prod ? 250 : 16
  storage_type               = "gp2"
  engine                     = "mariadb"
  engine_version             = "10.3.8"
  instance_class             = module.global_variables.is_prod ? "db.t3.medium" : "db.t3.micro"
  name                       = "ridi_pay"
  username                   = "ridi"
  password                   = data.aws_kms_secrets.rds.plaintext["password"]
  parameter_group_name       = aws_db_parameter_group.slave[0].name
  vpc_security_group_ids     = [aws_security_group.rds.id]
  auto_minor_version_upgrade = false
  backup_retention_period    = 7
  ca_cert_identifier         = "rds-ca-2019"
}

resource "aws_db_parameter_group" "master" {
  count  = module.global_variables.is_staging ? 0 : 1
  name   = "ridi-pay-${module.global_variables.env}-master"
  family = "mariadb10.3"
  parameter {
    name  = "read_only"
    value = "0"
  }
  parameter {
    name  = "collation_server"
    value = "utf8_unicode_ci"
  }
  parameter {
    name  = "init_connect"
    value = "SET NAMES utf8"
  }
  parameter {
    name  = "character_set_server"
    value = "utf8"
  }
  parameter {
    name  = "time_zone"
    value = "Asia/Seoul"
  }
}

resource "aws_db_parameter_group" "slave" {
  count  = module.global_variables.is_prod ? 1 : 0
  name   = "ridi-pay-${module.global_variables.env}-slave"
  family = "mariadb10.3"
  parameter {
    name  = "read_only"
    value = "1"
  }
  parameter {
    name  = "collation_server"
    value = "utf8_unicode_ci"
  }
  parameter {
    name  = "init_connect"
    value = "SET NAMES utf8"
  }
  parameter {
    name  = "character_set_server"
    value = "utf8"
  }
  parameter {
    name  = "time_zone"
    value = "Asia/Seoul"
  }
}

resource "aws_db_subnet_group" "rds" {
  count = module.global_variables.is_staging ? 0 : 1
  name  = "ridi-pay-${module.global_variables.env}"
  subnet_ids = [
    aws_subnet.private_2a.id,
    aws_subnet.private_2c.id,
  ]
}

