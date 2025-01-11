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
  container_definitions = jsonencode([
    {
      name      = local.app_name
      image     = aws_ecr_repository.chord-repository[0].repository_url+":latest"
      cpu       = 0.5
      memory    = 1
      essential = true
      portMappings = [
        {
          containerPort = 80
          hostPort      = 80
        }
      ]
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