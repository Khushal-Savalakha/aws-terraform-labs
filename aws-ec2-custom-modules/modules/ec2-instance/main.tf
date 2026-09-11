resource "aws_instance" "ec2_instance" {
  ami           = var.ami
  instance_type = var.instance_type
  count         = var.instance_count
  region       = var.aws_region

  tags = {
    Name = "Terraform-EC2-Instance"
  }
}