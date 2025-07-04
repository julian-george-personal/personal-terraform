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

resource "aws_secretsmanager_secret" "sendgrid-api-key" {
  name = "${local.app_name}-sendgrid-api-key"
}

resource "aws_secretsmanager_secret" "recover-password-template-id" {
  name = "${local.app_name}-recover-password-template-id"
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

resource "aws_secretsmanager_secret_version" "sendgrid-api-key" {
  secret_id     = aws_secretsmanager_secret.sendgrid-api-key.id
  secret_string = module.email-app.api_key_value
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

resource "aws_secretsmanager_secret_version" "recover-password-template-id" {
  secret_id     = aws_secretsmanager_secret.recover-password-template-id.id
  secret_string = module.password-recovery-email-template.template_id
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
    "JWT_SECRET"                   = aws_secretsmanager_secret.jwt_secret.arn
    "SENDGRID_API_KEY"             = aws_secretsmanager_secret.sendgrid-api-key.arn
    "RECOVER_PASSWORD_TEMPLATE_ID" = aws_secretsmanager_secret_version.recover-password-template-id.arn
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
      aws_secretsmanager_secret.jwt_secret.arn,
      aws_secretsmanager_secret.sendgrid-api-key.arn,
      aws_secretsmanager_secret.recover-password-template-id.arn
    ]
    effect = "Allow"
  }
}

resource "aws_iam_role_policy" "secrets_policy_attachment" {
  name   = "${local.app_name}-secrets-access"
  role   = module.application.iam_role_name
  policy = data.aws_iam_policy_document.secrets_policy.json
}