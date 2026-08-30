locals {
  app_name = "hedge-trimmer-ingestion"
}

# Reuses the autotrader's Kalshi/PandaScore credentials — same account,
# same API access, one fewer set of secrets to keep in sync.
data "aws_secretsmanager_secret" "kalshi_key_id" {
  name = "hedge-trimmer-autotrader-kalshi-key-id"
}

data "aws_secretsmanager_secret" "kalshi_private_key" {
  name = "hedge-trimmer-autotrader-kalshi-private-key"
}

data "aws_secretsmanager_secret" "pandascore_token" {
  name = "hedge-trimmer-autotrader-pandascore-token"
}

# Not Terraform-managed — created out of band. Looked up read-only so the
# task role's IAM policy below can reference its ARN.
data "aws_s3_bucket" "hedge_trimmer_data" {
  bucket = "hedge-trimmer-juliangeorge"
}

module "task" {
  source              = "../aws-ecs-fargate-scheduled-task"
  task_name           = local.app_name
  vpc_id              = var.vpc_id
  subnet_ids          = var.subnet_ids
  cpu                 = 512
  memory              = 2048
  schedule_expression = "rate(12 hours)"

  env_vars = {
    "KALSHI_SERIES_TICKER" = "KXCS2GAME"
    "INGEST_WINDOW_DAYS"   = "3"
  }
  env_secrets = {
    "KALSHI_KEY_ID"          = data.aws_secretsmanager_secret.kalshi_key_id.arn
    "KALSHI_PRIVATE_KEY_PEM" = data.aws_secretsmanager_secret.kalshi_private_key.arn
    "PANDASCORE_TOKEN"       = data.aws_secretsmanager_secret.pandascore_token.arn
  }
}

data "aws_iam_policy_document" "s3-policy" {
  statement {
    effect    = "Allow"
    actions   = ["s3:ListBucket"]
    resources = [data.aws_s3_bucket.hedge_trimmer_data.arn]
    condition {
      test     = "StringLike"
      variable = "s3:prefix"
      values   = ["kalshi/*", "pandascore/*"]
    }
  }
  statement {
    effect  = "Allow"
    actions = ["s3:GetObject", "s3:PutObject"]
    resources = [
      "${data.aws_s3_bucket.hedge_trimmer_data.arn}/kalshi/*",
      "${data.aws_s3_bucket.hedge_trimmer_data.arn}/pandascore/*",
    ]
  }
}

resource "aws_iam_role_policy" "s3-policy" {
  name   = "${local.app_name}-s3-access"
  role   = module.task.task_role_name
  policy = data.aws_iam_policy_document.s3-policy.json
}
