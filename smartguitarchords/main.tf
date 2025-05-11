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

module "email-app" {
  source      = "../sendgrid-email-app"
  domain_name = local.domain_name
  app_name    = local.app_name
}

resource "aws_route53_record" "sendgrid_cname" {
  for_each = {
    for idx in range(3) : idx => tolist(module.email-app.dns_records)[idx]
  }

  zone_id = module.domain.hosted_zone_id
  name    = each.value.host
  type    = "CNAME"
  ttl     = "3600"
  records = [each.value.data]
}

resource "aws_route53_record" "sendgrid_dmarc" {
  zone_id = module.domain.hosted_zone_id
  name    = "_dmarc.${local.domain_name}"
  type    = "TXT"
  ttl     = "3600"
  records = ["v=DMARC1; p=none;"]
}

module "password-recovery-email-template" {
  source        = "../sendgrid-email-template"
  template_name = "smartguitarchords-passwordrecovery"
  email_subject = "Reset your password"
  email_body    = file("./smartguitarchords/password-recovery-template.html")
}

module "application" {
  source   = "../aws-apprunner-application"
  app_name = local.app_name
  env_vars = {
    "DYNAMO_USER_TABLE_NAME" = aws_dynamodb_table.account_table.name
    "DOMAIN"                 = local.domain_name
  }
  env_secrets = {
    "JWT_SECRET"                   = aws_secretsmanager_secret.jwt_secret.arn
    "SENDGRID_API_KEY"             = module.email-app.api_key_value
    "RECOVER_PASSWORD_TEMPLATE_ID" = module.password-recovery-email-template.template_id
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