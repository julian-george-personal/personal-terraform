output "task_role_arn" {
  value = aws_iam_role.task-role.arn
}

output "task_role_name" {
  value = aws_iam_role.task-role.name
}

output "ecr_repository_url" {
  value = aws_ecr_repository.task.repository_url
}

output "cluster_name" {
  value = aws_ecs_cluster.task.name
}

output "log_group_name" {
  value = aws_cloudwatch_log_group.task.name
}
