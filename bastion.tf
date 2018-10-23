resource "aws_instance" "bastion" {
  ami = "${data.aws_ami.ubuntu.id}"
  availability_zone = "${aws_subnet.public_2a.availability_zone}"
  instance_type = "t2.nano"
  key_name = "bastion"
  vpc_security_group_ids = [
    "${aws_security_group.bastion.id}"
  ]
  subnet_id = "${aws_subnet.public_2a.id}"
  associate_public_ip_address = true
  tags {
    Name = "bastion"
  }
}

resource "aws_eip" "bastion" {
  vpc = true
  instance = "${aws_instance.bastion.id}"
}