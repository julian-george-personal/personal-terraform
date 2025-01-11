resource "aws_ecr_repository" "chords-repository" {
  count = var.is_enabled ? 1 : 0
  name                 = local.app_name
  image_tag_mutability = "IMMUTABLE"
}

resource "aws_ecs_cluster" "chords-cluster" {
  count = var.is_enabled ? 1 : 0
  name = local.app_name
}

resource "aws_ecs_task_definition" "chords-task" {
  count = var.is_enabled ? 1 : 0
  family = local.app_name
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu = 256
  memory = 512
  container_definitions = jsonencode([
    {
      name      = local.app_name
      image     = "${aws_ecr_repository.chords-repository[0].repository_url}:latest"
      cpu       = 256
      memory    = 512
      essential = true
    },
  ])
}

resource "aws_ecs_service" "chords-service" {
  count = var.is_enabled ? 1 : 0
  name          = local.app_name
  cluster       = aws_ecs_cluster.chords-cluster[0].id
  task_definition = aws_ecs_task_definition.chords-task[0].arn
  desired_count = 1
  launch_type   = "FARGATE"
}