/**
 * The Container Task - This is the actual task that will be later deployed
 * by our deployment scripts. This is designed to extract all variables
 * computed during the terraform plan and use it to render the JSON task definition.
 */
locals {
  default_file_container_task = "${path.module}/aws-container-task-definition.json"
  default_file_container_spec = "${path.module}/aws-container-task-spec.json"

  file_container_task         = var.ecs_task_definition == "" ? local.default_file_container_task : var.ecs_task_definition
  file_container_spec         = var.ecs_app_spec == "" ? local.default_file_container_spec : var.ecs_app_spec
}

data "template_file" "container_task" {
  template = file(local.file_container_task)

  vars = {
    image              = aws_ecr_repository.default.repository_url
    name               = local.cannonical_name
    port               = var.docker_web_port
    region             = data.aws_region.current.name
    log-group          = aws_cloudwatch_log_group.default.name
    family             = local.cannonical_name
    cpu                = var.ecs_cpu
    memory             = var.ecs_memory
    execution_role_arn = aws_iam_role.container.arn
    task_role_arn      = aws_iam_role.container.arn
    app_name           = var.docker_app_name
    environment        = var.app_environment
  }
}

data "template_file" "container_spec" {
  template = file(local.file_container_spec)

  vars = {
    image     = aws_ecr_repository.default.repository_url
    name      = local.cannonical_name
    port      = var.docker_web_port
    region    = data.aws_region.current.name
    log-group = aws_cloudwatch_log_group.default.name
  }
}