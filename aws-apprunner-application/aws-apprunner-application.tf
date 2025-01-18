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
  count       = var.is_dns_enabled ? 1 : 0
  domain_name = var.domain_name
  service_arn = aws_apprunner_service.apprunner.arn
}

data "aws_apprunner_hosted_zone_id" "apprunner-hosted-zone-id" {}

resource "aws_route53_record" "apprunner-alias-record" {
  count   = var.is_dns_enabled ? 1 : 0
  zone_id = var.hosted_zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = aws_apprunner_custom_domain_association.apprunner-domain-name[0].dns_target
    zone_id                = data.aws_apprunner_hosted_zone_id.apprunner-hosted-zone-id.id
    evaluate_target_health = true
  }
}