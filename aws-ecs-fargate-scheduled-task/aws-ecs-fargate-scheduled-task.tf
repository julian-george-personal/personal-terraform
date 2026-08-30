data "aws_region" "current" {}

data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

resource "aws_ecr_repository" "task" {
  name                 = var.task_name
  image_tag_mutability = "MUTABLE"
  lifecycle {
    prevent_destroy = false
  }
  force_delete = true
}

resource "aws_cloudwatch_log_group" "task" {
  name              = "/ecs/${var.task_name}"
  retention_in_days = var.log_retention_days
}

resource "aws_ecs_cluster" "task" {
  name = var.task_name
}

# Assumed by the ECS agent to pull the image from ECR, resolve env_secrets
# from Secrets Manager, and write to the log group.
data "aws_iam_policy_document" "execution-assumerole-policy" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "execution-role" {
  name               = "${var.task_name}-execution-role"
  assume_role_policy = data.aws_iam_policy_document.execution-assumerole-policy.json
}

resource "aws_iam_role_policy_attachment" "execution-role-managed-policy" {
  role       = aws_iam_role.execution-role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

data "aws_iam_policy_document" "execution-secrets-policy" {
  count = length(var.env_secrets) > 0 ? 1 : 0
  statement {
    effect    = "Allow"
    actions   = ["secretsmanager:GetSecretValue"]
    resources = values(var.env_secrets)
  }
}

resource "aws_iam_role_policy" "execution-secrets-policy" {
  count  = length(var.env_secrets) > 0 ? 1 : 0
  name   = "${var.task_name}-secrets-access"
  role   = aws_iam_role.execution-role.name
  policy = data.aws_iam_policy_document.execution-secrets-policy[0].json
}

# Assumed by the running container itself, for whatever AWS calls the task
# code makes (e.g. S3). Callers attach their own policies to this role —
# see outputs.tf.
data "aws_iam_policy_document" "task-assumerole-policy" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "task-role" {
  name               = "${var.task_name}-task-role"
  assume_role_policy = data.aws_iam_policy_document.task-assumerole-policy.json
}

resource "aws_ecs_task_definition" "task" {
  family                   = var.task_name
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = var.cpu
  memory                   = var.memory
  execution_role_arn       = aws_iam_role.execution-role.arn
  task_role_arn            = aws_iam_role.task-role.arn

  container_definitions = jsonencode([
    {
      name      = var.task_name
      image     = "${aws_ecr_repository.task.repository_url}:latest"
      essential = true
      command   = var.command
      environment = [
        for name, value in var.env_vars : { name = name, value = value }
      ]
      secrets = [
        for name, arn in var.env_secrets : { name = name, valueFrom = arn }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.task.name
          "awslogs-region"        = data.aws_region.current.region
          "awslogs-stream-prefix" = var.task_name
        }
      }
    }
  ])
}

# No NAT gateway: the task runs in a default-VPC public subnet with a
# public IP and an outbound-only security group, since this is a batch job
# hitting the internet (external APIs, S3) with nothing that needs to
# reach it inbound.
resource "aws_security_group" "task" {
  name        = "${var.task_name}-task-sg"
  description = "Outbound-only access for the ${var.task_name} scheduled task"
  vpc_id      = data.aws_vpc.default.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

data "aws_iam_policy_document" "scheduler-assumerole-policy" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["scheduler.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "scheduler-role" {
  name               = "${var.task_name}-scheduler-role"
  assume_role_policy = data.aws_iam_policy_document.scheduler-assumerole-policy.json
}

data "aws_iam_policy_document" "scheduler-run-task-policy" {
  statement {
    effect    = "Allow"
    actions   = ["ecs:RunTask"]
    resources = [aws_ecs_task_definition.task.arn]
  }
  statement {
    effect    = "Allow"
    actions   = ["iam:PassRole"]
    resources = [aws_iam_role.execution-role.arn, aws_iam_role.task-role.arn]
  }
}

resource "aws_iam_role_policy" "scheduler-run-task-policy" {
  name   = "${var.task_name}-run-task"
  role   = aws_iam_role.scheduler-role.name
  policy = data.aws_iam_policy_document.scheduler-run-task-policy.json
}

resource "aws_scheduler_schedule" "task" {
  name                         = var.task_name
  schedule_expression          = var.schedule_expression
  schedule_expression_timezone = "UTC"

  flexible_time_window {
    mode = "OFF"
  }

  target {
    arn      = aws_ecs_cluster.task.arn
    role_arn = aws_iam_role.scheduler-role.arn

    ecs_parameters {
      task_definition_arn = aws_ecs_task_definition.task.arn
      launch_type         = "FARGATE"

      network_configuration {
        subnets          = data.aws_subnets.default.ids
        security_groups  = [aws_security_group.task.id]
        assign_public_ip = true
      }
    }
  }
}
