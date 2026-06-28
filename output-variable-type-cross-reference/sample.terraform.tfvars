aws_access_key = "YOUR_AWS_ACCESS_KEY"
aws_secret_key = "YOUR_AWS_SECRET_KEY"
aws_region     = "ap-south-1"
username       = "test_user"
ami            = "test-ami"
instance_type  = "t2.small"
instance_count = 1
security_groups = [
  "launch-wizard-1",
  "launch-wizard-2",
]
ec2_tags = {
  Name        = "web-server"
  Environment = "production"
  Project     = "terraform-labs"
  Owner       = "test_user"
  ManagedBy   = "Terraform"
}