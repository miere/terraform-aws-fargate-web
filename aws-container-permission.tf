# Permissions
resource "aws_iam_role" "container" {
  name               = "${local.cannonical_name}-container"

  assume_role_policy = jsonencode({
    Version: "2012-10-17",
    Statement: [
      {
        Sid: "",
        Effect: "Allow",
        Principal: {
          Service: "ecs-tasks.amazonaws.com"
        },
        Action: "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_policy" "container" {
  name   = "${local.cannonical_name}-container"

  policy = jsonencode({
    Version: "2012-10-17",
    Statement: [
      {
        Effect: "Allow",
        Action: [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage"
        ],
        Resource: "*"
      },
      {
        Effect: "Allow",
        Action: [
          "logs:PutLogEvents",
          "logs:CreateLogStream",
          "cloudwatch:PutMetricData"
        ]
        Resource: "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "container" {
  role       = aws_iam_role.container.name
  policy_arn = aws_iam_policy.container.arn
}