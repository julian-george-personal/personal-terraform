output "arn" {
  value = aws_apprunner_service.apprunner.arn
}

output "iam_role_name" {
  value = aws_iam_role.apprunner-instance-role.name
}