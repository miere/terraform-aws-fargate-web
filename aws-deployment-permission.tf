# CodeDeploy Permissions
resource "aws_iam_role" "codedeploy" {
  name               = "${local.cannonical_name}-codedeploy"
  
  assume_role_policy = jsonencode({
    Version: "2012-10-17",
    Statement: [
      {
        Effect: "Allow",
        Action: "sts:AssumeRole",
        Principal: {
          Service: "codedeploy.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_policy" "codedeploy" {
  name   = "${local.cannonical_name}-codedeploy"

  policy = jsonencode({
    Version : "2012-10-17",
    Statement : [
      {
        Effect: "Allow",
        Resource: "*",
        Action: [
          "autoscaling:*",
          "cloudwatch:*",
          "ecs:*",
          "elasticloadbalancing:*",
          "codedeploy:*",
          "iam:PassRole",
          "SNS:Publish"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "codedeploy" {
  role       = aws_iam_role.codedeploy.name
  policy_arn = aws_iam_policy.codedeploy.arn
}