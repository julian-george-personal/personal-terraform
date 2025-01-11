resource "aws_ecr_repository" "chords-repository" {
    count = var.is_enabled ? 1 : 0
  name                 = local.app_name
  image_tag_mutability = "IMMUTABLE"
}

resource "aws_ecs_cluster" "chords-cluster" {
    count = var.is_enabled ? 1 : 0
  name = local.app_name
}

resource "aws_ecs_service" "chords-service" {
    count = var.is_enabled ? 1 : 0
  name          = local.app_name
  cluster       = aws_ecs_cluster.chords-cluster[0].id
  desired_count = 1
  launch_type   = "FARGATE"
}