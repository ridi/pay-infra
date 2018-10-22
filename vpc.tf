resource "aws_vpc" "vpc" {
  cidr_block = "${module.global_variables.is_staging ? "10.10.0.0/16" : "10.0.0.0/16"}"
  enable_dns_hostnames = true
  enable_dns_support = true
  instance_tenancy = "default"
  tags = {
    Name = "vpc-${module.global_variables.env}"
    Environment = "${module.global_variables.env}"
  }
}

resource "aws_subnet" "public_2a" {
  vpc_id = "${aws_vpc.vpc.id}"
  availability_zone = "ap-northeast-2a"
  cidr_block = "${module.global_variables.is_staging ? "10.10.0.0/24" : "10.0.0.0/24"}"
  tags {
    Name = "${module.global_variables.env}-public-2a"
  }
}

resource "aws_subnet" "public_2c" {
  vpc_id = "${aws_vpc.vpc.id}"
  availability_zone = "ap-northeast-2c"
  cidr_block = "${module.global_variables.is_staging ? "10.10.1.0/24" : "10.0.1.0/24"}"
  tags {
    Name = "${module.global_variables.env}-public-2c"
  }
}

resource "aws_subnet" "private_2a" {
  vpc_id = "${aws_vpc.vpc.id}"
  availability_zone = "ap-northeast-2a"
  cidr_block = "${module.global_variables.is_staging ? "10.10.10.0/24" : "10.0.10.0/24"}"
  tags {
    Name = "${module.global_variables.env}-private-2a"
  }
}

resource "aws_subnet" "private_2c" {
  vpc_id = "${aws_vpc.vpc.id}"
  availability_zone = "ap-northeast-2c"
  cidr_block = "${module.global_variables.is_staging ? "10.10.11.0/24" : "10.0.11.0/24"}"
  tags {
    Name = "${module.global_variables.env}-private-2c"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = "${aws_vpc.vpc.id}"
}
