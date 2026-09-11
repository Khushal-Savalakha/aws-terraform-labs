
variable "ami" {
  type    = string
}

variable "instance_type" {
  type    = string
  default = "t2.micro"

  validation {
    condition     = contains(["t2.micro", "t3.micro", "t3.small"], var.instance_type)
    error_message = "Only t2.micro, t3.micro, and t3.small are allowed for this lab."
  }
}

variable "instance_count" {
  type    = number
  default = 1

  validation {
    condition     = var.instance_count > 0 && var.instance_count <= 5
    error_message = "Instance count must be between 1 and 5."
  }
}

variable "aws_region" {
  type    = string
  default = "us-east-1"
}