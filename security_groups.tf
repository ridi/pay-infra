resource "aws_security_group" "rds" {
  vpc_id = "${aws_vpc.vpc.id}"
  name = "rds"
  description = "Allow inbound traffic in vpc"
  ingress {
    from_port = 3306
    to_port = 3306
    protocol = "tcp"
    cidr_blocks = [
      "10.0.0.0/16",
      "10.10.0.0/16"
    ]
  }
  egress {
    from_port = 3306
    to_port = 3306
    protocol = "tcp"
    cidr_blocks = [
      "10.0.0.0/16",
      "10.10.0.0/16"
    ]
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
    Name = "bastion"
  }
}
