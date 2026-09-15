terraform {
  backend "s3" {
    bucket       = "terraform-logs-007"
    key          = "production.tfstate/ap-south-1/terraform.tfstate"
    region       = "ap-south-1"
    use_lockfile = true
  }
}
