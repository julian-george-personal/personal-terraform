locals {
  app_name = "hedge-trimmer-autotrader"
}

resource "aws_dynamodb_table" "autotrader" {
  name         = local.app_name
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

resource "aws_secretsmanager_secret" "kalshi_key_id" {
  name = "${local.app_name}-kalshi-key-id"
}

resource "aws_secretsmanager_secret" "kalshi_private_key" {
  name = "${local.app_name}-kalshi-private-key"
}

resource "aws_secretsmanager_secret" "pandascore_token" {
  name = "${local.app_name}-pandascore-token"
}

resource "aws_secretsmanager_secret" "basic_auth_password" {
  name = "${local.app_name}-basic-auth-password"
}

module "application" {
  source   = "../aws-apprunner-application"
  app_name = local.app_name
  env_vars = {
    "DYNAMO_TABLE_NAME"    = aws_dynamodb_table.autotrader.name
    "KALSHI_SERIES_TICKER" = "KXCS2GAME"
    "BASIC_AUTH_USERNAME"  = var.basic_auth_username
  }
  env_secrets = {
    "KALSHI_KEY_ID"          = aws_secretsmanager_secret.kalshi_key_id.arn
    "KALSHI_PRIVATE_KEY_PEM" = aws_secretsmanager_secret.kalshi_private_key.arn
    "PANDASCORE_TOKEN"       = aws_secretsmanager_secret.pandascore_token.arn
    "BASIC_AUTH_PASSWORD"    = aws_secretsmanager_secret.basic_auth_password.arn
  }
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
      aws_dynamodb_table.autotrader.arn,
      "${aws_dynamodb_table.autotrader.arn}/*"
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
      aws_secretsmanager_secret.kalshi_key_id.arn,
      aws_secretsmanager_secret.kalshi_private_key.arn,
      aws_secretsmanager_secret.pandascore_token.arn,
      aws_secretsmanager_secret.basic_auth_password.arn,
    ]
    effect = "Allow"
  }
}

resource "aws_iam_role_policy" "secrets_policy_attachment" {
  name   = "${local.app_name}-secrets-access"
  role   = module.application.iam_role_name
  policy = data.aws_iam_policy_document.secrets_policy.json
}
