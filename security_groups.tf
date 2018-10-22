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
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
