resource "aws_db_instance" "master" {
  identifier = "ridi-pay-master"
  allocated_storage = 16
  storage_type = "gp2"
  engine = "mariadb"
  engine_version = "10.2.12"
  instance_class = "db.t2.micro"
  name = "ridi_pay"
  username = "ridi"
  password = "${data.aws_kms_secrets.rds.plaintext["password"]}"
  parameter_group_name = "${aws_db_parameter_group.master.name}"
  db_subnet_group_name = "${aws_db_subnet_group.rds.name}"
  vpc_security_group_ids = ["${aws_security_group.rds.id}"]
  auto_minor_version_upgrade = false
}

resource "aws_db_parameter_group" "master" {
  name   = "ridi-pay-master-pg"
  family = "mariadb10.2"
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

resource "aws_db_subnet_group" "rds" {
    name = "rds-subnet-group"
    subnet_ids = [
      "${aws_subnet.private_2a.id}",
      "${aws_subnet.private_2c.id}"
    ]
}
