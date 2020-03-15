# Code Deploy
resource "aws_codedeploy_app" "default" {
  compute_platform = "ECS"
  name             = local.cannonical_name
}

resource "aws_codedeploy_deployment_group" "default" {
  app_name               = aws_codedeploy_app.default.name
  deployment_config_name = "CodeDeployDefault.ECSAllAtOnce"
  deployment_group_name  = local.cannonical_name
  service_role_arn       = aws_iam_role.codedeploy.arn

  auto_rollback_configuration {
    enabled = true
    events  = ["DEPLOYMENT_FAILURE"]
  }

  blue_green_deployment_config {
    deployment_ready_option {
      action_on_timeout = "CONTINUE_DEPLOYMENT"
    }

    terminate_blue_instances_on_deployment_success {
      action                           = "TERMINATE"
      termination_wait_time_in_minutes = 1
    }
  }

  deployment_style {
    deployment_option = "WITH_TRAFFIC_CONTROL"
    deployment_type   = "BLUE_GREEN"
  }

  ecs_service {
    cluster_name = aws_ecs_cluster.default.name
    service_name = aws_ecs_service.default.name
  }

  load_balancer_info {
    target_group_pair_info {
      prod_traffic_route { listener_arns = [aws_alb_listener.https.arn] }
      target_group { name = aws_alb_target_group.blue.name }
      target_group { name = aws_alb_target_group.green.name }
    }
  }

  trigger_configuration {
    trigger_events  = local.codedeploy_trigger_events
    trigger_name    =  aws_sns_topic.codedeploy_events.name
    trigger_target_arn = aws_sns_topic.codedeploy_events.arn
  }
}


