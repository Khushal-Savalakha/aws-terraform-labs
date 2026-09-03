# --------------------------------------------------------------------------------
# ECR Repository for Application Images
# --------------------------------------------------------------------------------
resource "aws_ecr_repository" "app" {
  name                 = "eks-lab-app"
  image_tag_mutability = "IMMUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}
