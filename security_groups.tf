resource "aws_security_group" "rds" {
  vpc_id = "${aws_vpc.vpc.id}"
  name = "rds"
  ingress {
    from_port = 3306
    to_port = 3306
    protocol = "tcp"
    cidr_blocks = [
      "${aws_vpc.vpc.cidr_block}"
    ]
  }
  egress {
    from_port = 3306
    to_port = 3306
    protocol = "tcp"
    cidr_blocks = [
      "${aws_vpc.vpc.cidr_block}"
    ]
  }
  tags {
    Name = "rds-${module.global_variables.env}"
  }
}

resource "aws_security_group" "bastion" {
  name = "bastion"
  vpc_id = "${aws_vpc.vpc.id}"
  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = [
      "218.232.41.2/32",
      "218.232.41.3/32",
      "218.232.41.4/32",
      "218.232.41.5/32",
      "222.231.4.164/32",
      "222.231.4.165/32"
    ]
  }
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags {
    Name = "bastion-${module.global_variables.env}"
  }
}

resource "aws_security_group" "alb_http" {
  vpc_id = "${aws_vpc.vpc.id}"
  name = "alb_http"
  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = [
      "218.232.41.2/32",
      "218.232.41.3/32",
      "218.232.41.4/32",
      "218.232.41.5/32",
      "222.231.4.164/32",
      "222.231.4.165/32",
      "${aws_vpc.vpc.cidr_block}"
    ]
  }
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags {
    Name = "alb_http-${module.global_variables.env}"
  }
}

resource "aws_security_group" "alb_https" {
  vpc_id = "${aws_vpc.vpc.id}"
  name = "alb_https"
  ingress {
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = [
      "218.232.41.2/32",
      "218.232.41.3/32",
      "218.232.41.4/32",
      "218.232.41.5/32",
      "222.231.4.164/32",
      "222.231.4.165/32",
      "${aws_vpc.vpc.cidr_block}"
    ]
  }
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags {
    Name = "alb_https-${module.global_variables.env}"
  }
}
