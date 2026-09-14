provider "aws" {
  alias = "virginia"
  region    = "us-east-1"
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
}

provider "aws" {
  alias = "mumbai"
  region    = "ap-south-1"
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
}


module "security-group" {
  source = "./modules/network"
    providers = {
    aws.virginia = aws.virginia
    aws.mumbai   = aws.mumbai
  }
}