variable "ami" {
  description = "Amazon Machine Image Value"
  default     = "ami-0d5e8769671b48387"
}

variable "instance_type" {
  description = "Amazon Instance Type"
  default     = "t2.micro"
}

variable "instance_count" {
  description = "Total No.of Instances"
  default     = "1"
}