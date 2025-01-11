resource "aws_ecr_repository" "chords-repository" {
  name                 = local.app_name
  image_tag_mutability = "IMMUTABLE"
}

resource "aws_ecs_cluster" "chords-cluster" {
  name = local.app_name
}

data "aws_iam_policy_document" "ecs_tasks_assume_role" {
  statement {
    sid    = ""
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "chords-ecs-role" {
  name = "${local.app_name}-ecs-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_tasks_assume_role.json
}

resource "aws_iam_role_policy_attachment" "chords-ecs-perms" {
  role = aws_iam_role.chords-ecs-role.arn
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_ecs_task_definition" "chords-task" {
  family = local.app_name
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu = 256
  memory = 512 
  task_role_arn = aws_iam_role.chords-ecs-role.arn
  container_definitions = jsonencode([
    {
      name      = local.app_name
      image     = "${aws_ecr_repository.chords-repository.repository_url}:latest"
      cpu       = 256
      memory    = 512
      essential = true
    },
  ])
}

resource "aws_ecs_service" "chords-service" {
  name          = local.app_name
  cluster       = aws_ecs_cluster.chords-cluster.id
  task_definition = aws_ecs_task_definition.chords-task.arn
  desired_count = 1
  launch_type   = "FARGATE"
}