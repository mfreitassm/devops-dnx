resource "aws_ecr_repository" "laravel-docker" {
  name                 = "laravel-docker"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

}
