output "s3_policy_json" {
  value = data.aws_iam_policy_document.s3_policy.json
}