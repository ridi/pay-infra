resource "aws_security_group" "fargate" {
  vpc_id = aws_vpc.vpc.id
  name = "fargate"

  ingress {
    from_port = 80
    to_port = 80
    protocol = "TCP"
    cidr_blocks = [
      aws_vpc.vpc.cidr_block
    ]
  }
  
  # If the cidr block isn't same with '0.0.0.0/0', starting ecs tasks may be failed because it can't be able to fetch container images from aws ecr.
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "fargate-${module.global_variables.env}"
  }
}

resource "aws_security_group" "rds" {
  vpc_id = aws_vpc.vpc.id
  name   = "rds"
  ingress {
    from_port = 3306
    to_port   = 3306
    protocol  = "tcp"
    cidr_blocks = [
      aws_vpc.vpc.cidr_block,
    ]
  }
  egress {
    from_port = 3306
    to_port   = 3306
    protocol  = "tcp"
    cidr_blocks = [
      aws_vpc.vpc.cidr_block,
    ]
  }
  tags = {
    Name = "rds-${module.global_variables.env}"
  }
}

resource "aws_security_group" "bastion" {
  name   = "bastion"
  vpc_id = aws_vpc.vpc.id
  ingress {
    from_port = 22
    to_port   = 22
    protocol  = "tcp"
    cidr_blocks = [
      "218.232.41.2/32",
      "218.232.41.3/32",
      "218.232.41.4/32",
      "218.232.41.5/32",
      "222.231.4.164/32",
      "222.231.4.165/32",
    ]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "bastion-${module.global_variables.env}"
  }
}

resource "aws_security_group" "web" {
  vpc_id = aws_vpc.vpc.id
  name   = "web"
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "web-${module.global_variables.env}"
  }
}

resource "aws_security_group_rule" "allow_https_from_internet" {
  count             = module.global_variables.is_prod ? 1 : 0
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.web.id
}

resource "aws_security_group_rule" "allow_http_from_vpc" {
  type      = "ingress"
  from_port = 80
  to_port   = 80
  protocol  = "tcp"
  cidr_blocks = [
    aws_vpc.vpc.cidr_block,
  ]
  security_group_id = aws_security_group.web.id
}

resource "aws_security_group_rule" "allow_https_from_vpc" {
  type      = "ingress"
  from_port = 443
  to_port   = 443
  protocol  = "tcp"
  cidr_blocks = [
    aws_vpc.vpc.cidr_block,
  ]
  security_group_id = aws_security_group.web.id
}

resource "aws_security_group_rule" "allow_https_from_office" {
  count     = module.global_variables.is_prod ? 0 : 1
  type      = "ingress"
  from_port = 443
  to_port   = 443
  protocol  = "tcp"
  cidr_blocks = [
    "218.232.41.2/32",
    "218.232.41.3/32",
    "218.232.41.4/32",
    "218.232.41.5/32",
    "222.231.4.164/32",
    "222.231.4.165/32",
  ]
  security_group_id = aws_security_group.web.id
}

resource "aws_security_group_rule" "allow_test_store" {
  count             = module.global_variables.is_test ? 1 : 0
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["52.78.20.56/32"]
  security_group_id = aws_security_group.web.id
}

resource "aws_security_group_rule" "allow_staging_store" {
  count             = module.global_variables.is_staging ? 1 : 0
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["115.68.53.150/32"]
  security_group_id = aws_security_group.web.id
}

resource "aws_security_group" "ssh_from_bastion" {
  vpc_id = aws_vpc.vpc.id
  name   = "ssh-from-bastion"
  ingress {
    from_port = 22
    to_port   = 22
    protocol  = "tcp"
    security_groups = [
      aws_security_group.bastion.id,
    ]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "ssh-from-bastion-${module.global_variables.env}"
  }
}

