# TODO make this private
resource "aws_ecr_repository" "apprunner-repository" {
  name                 = "${var.app_name}-repository"
  image_tag_mutability = "IMMUTABLE"
}

resource "aws_apprunner_service" "example" {
  service_name = var.app_name

  source_configuration {
    image_repository {
      image_identifier      = "${aws_ecr_repository.apprunner-repository.repository_url}:latest"
      image_repository_type = "ECR"
    }
    auto_deployments_enabled = true
  }

  instance_configuration {
    cpu = 256
    memory = 512
  }

  network_configuration {
    ingress_configuration {
      is_publicly_accessible = true
    }
  }
}