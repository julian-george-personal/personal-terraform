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

resource "aws_secretsmanager_secret" "resend-api-key" {
  name = "${local.app_name}-resend-api-key"
}

resource "aws_secretsmanager_secret" "sentry-dsn" {
  name = "${local.app_name}-sentry-dsn"
}

module "email-app" {
  source      = "../resend-email-app"
  domain_name = local.domain_name
  app_name    = local.app_name
}

resource "aws_secretsmanager_secret_version" "resend-api-key" {
  secret_id     = aws_secretsmanager_secret.resend-api-key.id
  secret_string = module.email-app.api_key_token
}

resource "aws_route53_record" "resend_dkim" {
  zone_id = module.domain.hosted_zone_id
  name    = module.email-app.dkim_records[0].name
  type    = module.email-app.dkim_records[0].type
  ttl     = 3600
  records = [module.email-app.dkim_records[0].value]
}

resource "aws_route53_record" "resend_spf_txt" {
  zone_id = module.domain.hosted_zone_id
  name    = module.email-app.spf_txt_record.name
  type    = module.email-app.spf_txt_record.type
  ttl     = 3600
  records = [module.email-app.spf_txt_record.value]
}

resource "aws_route53_record" "resend_spf_mx" {
  zone_id = module.domain.hosted_zone_id
  name    = module.email-app.spf_mx_record.name
  type    = module.email-app.spf_mx_record.type
  ttl     = 3600
  records = ["${module.email-app.spf_mx_record.priority} ${module.email-app.spf_mx_record.value}"]
}

resource "aws_dynamodb_table" "account_table" {
  name         = "${local.app_name}-accounts"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "PK"
  range_key    = "SK"

  attribute {
    name = "PK"
    type = "S"
  }

  attribute {
    name = "SK"
    type = "S"
  }
}


resource "aws_route53_record" "improvmx_mx" {
  zone_id = module.domain.hosted_zone_id
  name    = local.domain_name
  type    = "MX"
  ttl     = "3600"
  records = [
    "10 mx1.improvmx.com",
    "20 mx2.improvmx.com"
  ]
}

resource "aws_route53_record" "improvmx_spf" {
  zone_id = module.domain.hosted_zone_id
  name    = local.domain_name
  type    = "TXT"
  ttl     = "3600"
  records = ["v=spf1 include:spf.improvmx.com ~all"]
}

module "application" {
  source   = "../aws-apprunner-application"
  app_name = local.app_name
  env_vars = {
    "DYNAMO_USER_TABLE_NAME" = aws_dynamodb_table.account_table.name
    "DOMAIN"                 = local.domain_name
  }
  env_secrets = {
    "JWT_SECRET"     = aws_secretsmanager_secret.jwt_secret.arn
    "RESEND_API_KEY" = aws_secretsmanager_secret.resend-api-key.arn
    "SENTRY_DSN"     = aws_secretsmanager_secret.sentry-dsn.arn
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
      aws_dynamodb_table.account_table.arn,
      "${aws_dynamodb_table.account_table.arn}/*"
    ]
    effect = "Allow"
  }

}

resource "aws_iam_role_policy" "dynamo_table_permissions" {
  name   = "${local.app_name}-dynamo-readwrite"
  role   = module.application.iam_role_name
  policy = data.aws_iam_policy_document.dynamo-policy.json
}

data "aws_iam_policy_document" "secrets_policy" {
  statement {
    actions = [
      "secretsmanager:GetSecretValue",
    ]
    resources = [
      # when you make a new secret you need to add it here
      aws_secretsmanager_secret.jwt_secret.arn,
      aws_secretsmanager_secret.resend-api-key.arn,
      aws_secretsmanager_secret.sentry-dsn.arn
    ]
    effect = "Allow"
  }
}

resource "aws_iam_role_policy" "secrets_policy_attachment" {
  name   = "${local.app_name}-secrets-access"
  role   = module.application.iam_role_name
  policy = data.aws_iam_policy_document.secrets_policy.json
}