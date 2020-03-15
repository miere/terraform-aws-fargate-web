/**
 * The ECS + Fargate cluster defitition and its dependencies.
 */

# CloudWatch Logs
resource "aws_cloudwatch_log_group" "default" {
  name              = local.cannonical_name
  retention_in_days = var.logs_retention_in_days
}

# Docker Registry Repository
resource "aws_ecr_repository" "default" {
  name = local.cannonical_name
}

# ECS
resource "aws_ecs_cluster" "default" {
  name = local.cannonical_name
}

# Initial task - it is required as Fargate expects a task to
# be sucessfully deployed so you cluster is considered created
# with success.
resource "aws_ecs_task_definition" "initial" {
  family                   = local.cannonical_name
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = var.ecs_cpu
  memory                   = var.ecs_memory
  execution_role_arn       = aws_iam_role.container.arn
  task_role_arn            = aws_iam_role.container.arn

  container_definitions    = jsonencode([
    {
      name: local.cannonical_name,
      image: "python:2-alpine",
      cpu: 256,
      memory: 512,
      essential: true,
      command: [
        "/bin/sh", "-c",
        "wget https://bit.ly/2MJPCKB -O -  | python - ${var.docker_web_port}" ],
      workingDirectory: "/tmp",
      portMappings: [{
        containerPort: var.docker_web_port,
        hostPort: var.docker_web_port
      }]
    }
  ])
}

# The Service Creation
locals {
  remote_docker_image = "${aws_ecs_task_definition.initial.family}:${aws_ecs_task_definition.initial.revision}"
}

resource "aws_ecs_service" "default" {
  name            = local.cannonical_name
  task_definition = local.remote_docker_image
  cluster         = aws_ecs_cluster.default.id
  desired_count   = var.ecs_desired_count
  launch_type     = "FARGATE"

  network_configuration {
    assign_public_ip = true
    security_groups  = [aws_security_group.instances.id]
    subnets          = var.ecs_subnet_ids
  }

  load_balancer {
    target_group_arn = aws_alb_target_group.blue.arn
    container_name   = local.cannonical_name
    container_port   = var.docker_web_port
  }

  deployment_controller {
    type = "CODE_DEPLOY"
  }

  depends_on = [
    aws_alb_target_group.blue,
    aws_alb_listener.https,
    aws_alb_listener.http,
    aws_alb.default,
    aws_cloudwatch_log_group.default
  ]

  lifecycle {
    ignore_changes = [
      task_definition,
      desired_count,
      load_balancer
    ]
  }
}
