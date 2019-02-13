resource "aws_instance" "bastion" {
  ami = "${data.aws_ami.ubuntu.id}"
  availability_zone = "${aws_subnet.public_2a.availability_zone}"
  instance_type = "t3.nano"
  key_name = "${var.bastion_key_pair["${module.global_variables.env}"]}"
  vpc_security_group_ids = [
    "${aws_security_group.bastion.id}"
  ]
  subnet_id = "${aws_subnet.public_2a.id}"
  associate_public_ip_address = true
  tags {
    Name = "bastion-${module.global_variables.env}"
  }
}

resource "aws_eip" "bastion" {
  count = "${module.global_variables.is_prod ? 1 : 0}"
  instance = "${aws_instance.bastion.id}"
  vpc = true
  depends_on = ["aws_internet_gateway.igw"]
}
