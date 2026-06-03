
#main resource creation script
resource "aws_instance" "AWSServer" {
  count           = var.instance_count
  ami             = var.ami
  instance_type   = var.instance_type
  key_name        = "Terraform"
  security_groups = ["launch-wizard-1"]
  tags = {
    Name = "EC2 VM - ${count.index}"
  }
}