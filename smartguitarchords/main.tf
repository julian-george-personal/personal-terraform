locals {
  app_name    = "smartguitarchords"
  domain_name = "smartguitarchords.com"
}

module "domain" {
  source      = "../aws-route53-domain"
  domain_name = local.domain_name
}

resource "aws_secretsmanager_secret" "jwt_secret" {
  name = "${local.app_name}-jwt-secret"
}

data "aws_secretsmanager_secret_version" "jwt_secret" {
  depends_on = [aws_secretsmanager_secret.jwt_secret]
  secret_id  = aws_secretsmanager_secret.jwt_secret.id
}

resource "aws_dynamodb_table" "account_table" {
  name         = "${local.app_name}-accounts"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "username"

  attribute {
    name = "username"
    type = "S"
  }

  attribute {
    name = "email"
    type = "S"
  }

  global_secondary_index {
    name            = "EmailIndex"
    hash_key        = "email"
    projection_type = "ALL"
  }
}

module "application" {
  source   = "../aws-apprunner-application"
  app_name = local.app_name
  env_vars = {
    "DYNAMO_USER_TABLE_NAME" = aws_dynamodb_table.account_table.name
    "DOMAIN"                 = local.domain_name
  }
  env_secrets = {
    "JWT_SECRET" = data.aws_secretsmanager_secret_version.jwt_secret.secret_string
  }
}

module "dns" {
  source         = "../aws-apprunner-dns"
  depends_on     = [module.application]
  hosted_zone_id = module.domain.hosted_zone_id
  domain_name    = local.domain_name
  apprunner_arn  = module.application.arn
}

module "dns-personal" {
  source         = "../aws-apprunner-dns"
  depends_on     = [module.application]
  hosted_zone_id = var.personal_domain_hosted_zone_id
  domain_name    = "${local.app_name}.${var.personal_domain_name}"
  apprunner_arn  = module.application.arn
}


data "aws_iam_policy_document" "dynamo-policy" {
  statement {
    actions = [
      "dynamodb:GetItem",
      "dynamodb:Query",
      "dynamodb:Scan",
      "dynamodb:PutItem",
      "dynamodb:UpdateItem",
      "dynamodb:DeleteItem"
    ]
    resources = [
      aws_dynamodb_table.account_table.arn
    ]
    effect = "Allow"
  }

}

resource "aws_iam_role_policy" "dynamo_table_permissions" {
  name   = "${local.app_name}-dynamo-readwrite"
  role   = module.application.iam_role_name
  policy = data.aws_iam_policy_document.dynamo-policy.json
}

module "email" {
  source         = "../aws-ses-email"
  domain_name    = local.domain_name
  app_name       = local.app_name
  hosted_zone_id = module.domain.hosted_zone_id
}

data "aws_iam_policy_document" "secrets_policy" {
  statement {
    actions = [
      "secretsmanager:GetSecretValue",
    ]
    resources = [
      aws_secretsmanager_secret.jwt_secret.arn
    ]
    effect = "Allow"
  }
}

resource "aws_iam_role_policy" "secrets_policy_attachment" {
  name   = "${local.app_name}-secrets-access"
  role   = module.application.iam_role_name
  policy = data.aws_iam_policy_document.secrets_policy.json
}
