resource "aws_ecr_repository" "platform_api" {
  name = "${var.project_name}-api"

  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_ecr_repository" "platform_portal" {
  name = "${var.project_name}-portal"

  image_scanning_configuration {
    scan_on_push = true
  }
}
