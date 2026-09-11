module "ec2-instance" {
  source         = "./modules/ec2-instance"
  ami            = "ami-090d68841c2a28756"
  instance_type  = "t2.micro"
  instance_count = 1
  aws_region     = var.aws_region
}

#  Allocate the Elastic IP
resource "aws_eip" "example" {
  domain     = "vpc"
  instance   = module.ec2-instance.instance_id
  depends_on = [module.ec2-instance]
}

