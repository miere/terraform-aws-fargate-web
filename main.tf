# Configuring other providers
provider "archive" { version = "~> 1.2" }
provider "local" { version = "~> 1.1" }
provider "external" { version = "~> 1.2" }
provider "template" { version = "~> 2.1" }
provider "null" { version = "~> 2.0" }

# VPC
data "aws_vpc" "default" {
  id = var.vpc_id
}

data "aws_region" "current" {}