resource "aws_ecr_repository" "apprunner-repository" {
  name                 = var.app_name
  image_tag_mutability = "MUTABLE"
  lifecycle {
    prevent_destroy = false
  }
  force_delete = true
}

data "aws_iam_policy_document" "apprunner-builder-assumerole-policy" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["build.apprunner.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "apprunner-builder-role" {
  name               = "${var.app_name}-apprunner-builder-role"
  assume_role_policy = data.aws_iam_policy_document.apprunner-builder-assumerole-policy.json
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
    resources = [aws_ecr_repository.apprunner-repository.arn]
  }
}

resource "aws_iam_role_policy" "apprunner-ecr-policy" {
  name   = "${var.app_name}-ecr-access"
  role   = aws_iam_role.apprunner-builder-role.name
  policy = data.aws_iam_policy_document.apprunner-ecr-policy.json
}

data "aws_iam_policy_document" "apprunner-instance-assumerole-policy" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["tasks.apprunner.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "apprunner-instance-role" {
  name               = "${var.app_name}-apprunner-instance-role"
  assume_role_policy = data.aws_iam_policy_document.apprunner-instance-assumerole-policy.json
}

resource "aws_apprunner_service" "apprunner" {
  depends_on = [ aws_iam_role.apprunner-builder-role, aws_iam_role.apprunner-instance-role, aws_ecr_repository.apprunner-repository ]
  service_name = var.app_name

  source_configuration {
    authentication_configuration {
      access_role_arn = aws_iam_role.apprunner-builder-role.arn
    }
    image_repository {
      image_identifier      = "${aws_ecr_repository.apprunner-repository.repository_url}:latest"
      image_repository_type = "ECR"
      image_configuration {
        port                          = 80
        runtime_environment_secrets   = var.env_secrets
        runtime_environment_variables = var.env_vars
      }
    }
    auto_deployments_enabled = true
  }

  instance_configuration {
    cpu               = 256
    memory            = 512
    instance_role_arn = aws_iam_role.apprunner-instance-role.arn
  }

  network_configuration {
    ingress_configuration {
      is_publicly_accessible = true
    }
  }
}