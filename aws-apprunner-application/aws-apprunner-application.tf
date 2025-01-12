# TODO make this private
resource "aws_ecr_repository" "apprunner-repository" {
  name                 = var.app_name
  image_tag_mutability = "MUTABLE"
}

data "aws_iam_policy_document" "apprunner-assumerole-policy" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["build.apprunner.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "apprunner-role" {
  name               = "${var.app_name}-apprunner-role"
  assume_role_policy = data.aws_iam_policy_document.apprunner-assumerole-policy.json
}

data "aws_iam_policy_document" "apprunner-ecr-policy" {
  statement {
    effect = "Allow"
    actions = [
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchCheckLayerAvailability",
      "ecr:BatchGetImage",
      "ecr:DescribeImages",
      "ecr:GetAuthorizationToken"
    ]
    resources = ["*"]
  }

}

resource "aws_iam_role_policy" "apprunner-ecr-policy" {
  name   = "${var.app_name}-ecr-access"
  role   = aws_iam_role.apprunner-role.name
  policy = data.aws_iam_policy_document.apprunner-ecr-policy.json
}

resource "aws_apprunner_service" "apprunner" {
  service_name = var.app_name

  source_configuration {
    authentication_configuration {
      access_role_arn = aws_iam_role.apprunner-role.arn
    }
    image_repository {
      image_identifier      = "${aws_ecr_repository.apprunner-repository.repository_url}:latest"
      image_repository_type = "ECR"
      image_configuration {
        port = 80
      }
    }
    auto_deployments_enabled = true
  }

  instance_configuration {
    cpu    = 256
    memory = 512
  }

  network_configuration {
    ingress_configuration {
      is_publicly_accessible = true
    }
  }
}

resource "aws_apprunner_custom_domain_association" "apprunner-domain-name" {
  domain_name = var.domain_name
  service_arn = aws_apprunner_service.apprunner.arn
}