output "ecs_resource_id" {
  description = "The just created ECS resource Id. May be useful to create CloudWatch metrics."
  value = "service/${aws_ecs_cluster.default.name}/${aws_ecs_service.default.name}"
}

output "iam_role_arm" {
  description = "The IAM Role attached to Fargate services"
  value = aws_iam_role.container.arn
}

output "iam_role_name" {
  description = "The IAM Role attached to Fargate services"
  value = aws_iam_role.container.name
}

output "ec2_security_groups_instances_name" {
  description = "The name of the EC2 Security Group attached to instances/tasks"
  value = aws_security_group.instances.name
}

output "ec2_security_groups_instances_arn" {
  description = "The ARN of the EC2 Security Group attached to instances/tasks"
  value = aws_security_group.instances.arn
}

output "ec2_security_groups_instances_id" {
  description = "The id of the EC2 Security Group attached to instances/tasks"
  value = aws_security_group.instances.id
}

output "lb_arn" {
  description = "The Load Balancer arn"
  value = aws_alb.default.arn
}

output "lb_name" {
  description = "The Load Balancer name"
  value = aws_alb.default.name
}

output "lb_fqdns" {
  description = "The original Load Balancer's FQDN"
  value = aws_alb.default.dns_name
}

output "route53_record" {
  description = "The created FQDN entry for this service"
  value = aws_route53_record.submain.fqdn
}

output "log_group_arn" {
  value = aws_cloudwatch_log_group.default.arn
}

output "log_group_name" {
  value = aws_cloudwatch_log_group.default.name
}

output "sns_codedeploy_events_arn" {
  description = "The SNS Topic for CodeDeploy events"
  value = aws_sns_topic.codedeploy_events.arn
}
