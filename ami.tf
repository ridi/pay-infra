data "aws_ami" "amazon_ecs_optimized" {
  most_recent = true
  filter {
    name = "name"
    values = ["amzn-ami-*-amazon-ecs-optimized"]
  }
  owners = ["amazon"]
}
