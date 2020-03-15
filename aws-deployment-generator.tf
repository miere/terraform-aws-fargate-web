/**
 * Generates a folder with the required scripts to perform
 * the deploy independently from terraform execution.
 */
locals {
  docker_app_name = var.docker_app_name == "" ? var.app_name : var.docker_app_name
  deployment_root_path = var.deployment_folder_path == "" ? "${var.docker_folder_relative_path}/../deployment" : var.deployment_folder_path
}

resource "null_resource" "deploy_new_task" {

  triggers = {
    docker_image = var.docker_app_name
    docker_parent_image = var.docker_parent_image
    docker_root_path = var.docker_folder_relative_path
    app_version  = var.app_version
    task_def     = base64sha256(data.template_file.container_task.rendered)
    image        = aws_ecr_repository.default.repository_url
    service      = aws_ecs_service.default.name
    cluster      = aws_ecs_cluster.default.arn
    deploy_spec  = base64sha256(data.template_file.container_spec.rendered)
    deploy_app   = aws_codedeploy_app.default.name
    deploy_group = aws_codedeploy_deployment_group.default.deployment_group_name
    deployment_root_path = var.deployment_folder_path
  }

  provisioner "local-exec" {
    command = "$DEPLOY $REGION $IMAGE $SERVICE $CLUSTER \"$TASK_DEF\" \"$DOCKER_ROOT\" \"$DOCKER_PARENT\" $DEPLOY_APP $DEPLOY_GRP \"$DEPLOY_SPEC\" \"$DEPLOY_ROOT\" $ENVIRONMENT $APP_NAME"

    environment = {
      DEPLOY      = "${path.module}/aws-deployment-generator.sh"
      REGION      = data.aws_region.current.name
      IMAGE       = aws_ecr_repository.default.repository_url
      SERVICE     = aws_ecs_service.default.name
      CLUSTER     = aws_ecs_cluster.default.arn
      TASK_DEF    = data.template_file.container_task.rendered
      DOCKER_ROOT = var.docker_folder_relative_path
      DOCKER_PARENT = var.docker_parent_image
      DEPLOY_APP  = aws_codedeploy_app.default.name
      DEPLOY_GRP  = aws_codedeploy_deployment_group.default.deployment_group_name
      DEPLOY_SPEC = data.template_file.container_spec.rendered
      DEPLOY_ROOT = local.deployment_root_path
      ENVIRONMENT = var.app_environment
      APP_NAME    = local.docker_app_name
    }
  }

  depends_on = [
    aws_ecr_repository.default,
    aws_ecs_cluster.default,
    aws_ecs_service.default,
    aws_ecs_task_definition.initial,
  ]
}