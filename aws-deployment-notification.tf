locals {
  codedeploy_trigger_events  = [
    "DeploymentStart", "DeploymentSuccess", "DeploymentFailure",
    "DeploymentStop", "DeploymentRollback",
    "InstanceStart", "InstanceSuccess", "InstanceFailure"
  ]
}

resource "aws_sns_topic" "codedeploy_events" {
  name = "${local.cannonical_name}-codedeploy-events"
}
