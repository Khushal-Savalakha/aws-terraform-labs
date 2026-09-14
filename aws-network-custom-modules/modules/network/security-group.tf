terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      configuration_aliases = [ aws.virginia, aws.mumbai ]
    }
  }
}

resource "aws_security_group" "dev" {
    provider    = aws.mumbai
    name        = "dev-sg"
}

resource "aws_security_group" "prod" {
    provider    = aws.virginia
    name        = "prod-sg"
}
