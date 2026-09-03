variable "aws_access_key" {
  type = string
}

variable "aws_secret_key" {
  type = string
}

variable "github_repo" {
  type        = string
  description = "Your GitHub repository in 'owner/repo' format (e.g. my-org/my-app)"
  default     = "your-username/your-repo"
}

variable "db_username" {
  type        = string
  description = "Username for the RDS database"
}

variable "db_password" {
  type        = string
  description = "Password for the RDS database"
  sensitive   = true
}

variable "cluster_name" {
  type        = string
  description = "Name for the EKS cluster"
  default     = "dev-eks-fargate"
}

variable "aws_region" {
  type        = string
  description = "AWS region for the EKS cluster"
  default     = "ap-south-1"
}