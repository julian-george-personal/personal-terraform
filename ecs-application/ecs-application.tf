resource "aws_ecr_repository" "repository" {
  name                 = var.app_name
  image_tag_mutability = "IMMUTABLE"
}

resource "aws_ecs_cluster" "cluster" {
  name = var.app_name
}

data "aws_iam_policy_document" "ecs-tasks-assume-role" {
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

resource "aws_iam_role" "ecs-task-role" {
  name = "${var.app_name}-ecs-role"
  assume_role_policy = data.aws_iam_policy_document.ecs-tasks-assume-role.json
}

resource "aws_iam_role_policy_attachment" "ecs-task-execution-attachment" {
  role = aws_iam_role.ecs-task-role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_vpc" "ecs-vpc" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "ecs-subnet" {
  cidr_block = "10.0.0.0/16"
  vpc_id     = aws_vpc.ecs-vpc.id
}

resource "aws_ecs_task_definition" "ecs-task" {
  family = var.app_name
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu = 256
  memory = 512 
  task_role_arn = aws_iam_role.ecs-task-role.arn
  execution_role_arn = aws_iam_role.ecs-task-role.arn
  container_definitions = jsonencode([
    {
      name      = var.app_name
      image     = "${aws_ecr_repository.repository.repository_url}:latest"
      cpu       = 256
      memory    = 512
      essential = true
    },
  ])
}

resource "aws_ecs_service" "ecs-service" {
  name          = var.app_name
  cluster       = aws_ecs_cluster.cluster.id
  task_definition = aws_ecs_task_definition.ecs-task.arn
  desired_count = 1
  launch_type   = "FARGATE"
  network_configuration {
    subnets = [aws_subnet.ecs-subnet.id]
    assign_public_ip = true
  }
}