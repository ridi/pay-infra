resource "aws_security_group" "fargate" {
  vpc_id = aws_vpc.vpc.id
  name   = "fargate"

  ingress {
    from_port = 80
    to_port   = 80
    protocol  = "tcp"
    cidr_blocks = [
      aws_vpc.vpc.cidr_block
    ]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "fargate-${module.global_variables.env}"
  }
}

resource "aws_security_group" "ecr_vpc_endpoint" {
  vpc_id = aws_vpc.vpc.id
  name   = "ecr-vpc-endpoint"

  ingress {
    from_port = 443
    to_port   = 443
    protocol  = "tcp"
    cidr_blocks = [
      aws_vpc.vpc.cidr_block
    ]
  }

  egress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    cidr_blocks = [
      aws_vpc.vpc.cidr_block
    ]
  }

  tags = {
    Name = "ecr-vpc-endpoint-${module.global_variables.env}"
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
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.office_cidr_blocks
  }
  egress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.office_cidr_blocks
  }
  tags = {
    Name = "bastion-${module.global_variables.env}"
  }
}

resource "aws_security_group_rule" "bastion_awslogs_outbound" {
  type              = "egress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.bastion.id
}

resource "aws_security_group_rule" "bastion_internal_outbound_ports" {
  type              = "egress"
  count             = length(var.bastion_internal_outbound_ports)
  from_port         = element(var.bastion_internal_outbound_ports, count.index)
  to_port           = element(var.bastion_internal_outbound_ports, count.index)
  protocol          = "tcp"
  cidr_blocks       = [aws_vpc.vpc.cidr_block]
  security_group_id = aws_security_group.bastion.id
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
