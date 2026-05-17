output "function_arn" {
  value = aws_lambda_function.lambda.arn
}

output "function_name" {
  value = aws_lambda_function.lambda.function_name
}

output "role_arn" {
  value = aws_iam_role.lambda-role.arn
}

output "function_url" {
  value = aws_lambda_function_url.lambda.function_url
}
