data "aws_iam_policy_document" "lambda-assumerole-policy" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "lambda-role" {
  name               = "${var.function_name}-lambda-role"
  assume_role_policy = data.aws_iam_policy_document.lambda-assumerole-policy.json
}

resource "aws_iam_role_policy_attachment" "lambda-basic-execution" {
  role       = aws_iam_role.lambda-role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

data "aws_iam_policy_document" "lambda-s3-policy" {
  statement {
    effect    = "Allow"
    actions   = ["s3:GetObject"]
    resources = ["arn:aws:s3:::${var.bucket_name}/${var.function_name}.zip"]
  }
}

resource "aws_iam_role_policy" "lambda-s3-policy" {
  name   = "${var.function_name}-s3-access"
  role   = aws_iam_role.lambda-role.name
  policy = data.aws_iam_policy_document.lambda-s3-policy.json
}

resource "aws_cloudwatch_log_group" "lambda-logs" {
  name              = "/aws/lambda/${var.function_name}"
  retention_in_days = 14
}

resource "aws_lambda_function" "lambda" {
  depends_on                     = [aws_iam_role_policy_attachment.lambda-basic-execution, aws_iam_role_policy.lambda-s3-policy, aws_cloudwatch_log_group.lambda-logs]
  function_name                  = var.function_name
  role                           = aws_iam_role.lambda-role.arn
  handler                        = var.handler
  runtime                        = var.runtime
  s3_bucket                      = var.bucket_name
  s3_key                         = "${var.function_name}.zip"
  reserved_concurrent_executions = var.max_concurrent_executions

  environment {
    variables = merge(var.env_vars, var.env_secrets)
  }
}
