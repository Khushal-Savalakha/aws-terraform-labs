provider "aws" {
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
  region     = var.aws_region
}

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

# ------------------------------------------------------------------------------
# Local Data Source
# Reads the contents of a local file from the current module directory.
# No AWS authentication is required for this data source.
# ------------------------------------------------------------------------------
data "local_file" "example" {
  filename = "${path.module}/demo.txt"
}

output "file_content" {
  value = data.local_file.example.content
}

# ------------------------------------------------------------------------------
# AWS AMI Data Source
# Retrieves the latest Ubuntu 24.04 LTS AMI published by Amazon.
# The AMI ID is then used while creating the EC2 instance.
# ------------------------------------------------------------------------------
data "aws_ami" "my_ami" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }
}

# Creates an EC2 instance using the AMI returned by the data source.
resource "aws_instance" "web" {
  ami           = data.aws_ami.my_ami.id
  instance_type = "t2.micro"

  tags = {
    Name = "WebServer"
  }
}

# ------------------------------------------------------------------------------
# AWS EC2 Data Source
# Reads information about an existing EC2 instance.
#
# NOTE:
# - This data source does NOT create an EC2 instance.
# - Terraform expects at least one existing instance that matches the filter.
# - If no matching instance is found, Terraform returns an error.
# ------------------------------------------------------------------------------
data "aws_instance" "example" {
  filter {
    name   = "tag:Team"
    values = ["Production"]
  }
}