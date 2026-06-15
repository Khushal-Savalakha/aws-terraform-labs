variable "aws_access_key" {
  type        = string
}

variable "aws_secret_key" {
  type        = string
}

variable "aws_region" {
  type        = string
}

variable "username" {
  type = string
}

variable "ami" {
  description = "Amazon Machine Image Value"
  default     = "ami-0d5e8769671b48387"
  type = string
}

variable "instance_type" {
  description = "Amazon Instance Type"
  default     = "t2.micro"
  type = string
}

variable "instance_count" {
  description = "Total No.of Instances"
  default     = 1
  type = number
}

variable "security_groups" {
  description = "List of security groups"
  type = list(string)
}