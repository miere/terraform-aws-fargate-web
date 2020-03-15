# terraform-ecs-ha
This is a custom terraform module designed to leverage Docker applications with
_zero downtime deployment_ using AWS Fargate.

## Basic usage
To get started with module you have to use it as a terraform module on your project.
```hlc
module "terraform-ecs-ha" {
  source = "miere/aws/fargate-ha-web.git"

  // Basic App Details
  app_name = "test-api"
  app_version = uuid()

  // Where to place the deployment scripts
  deployment_folder_path = "${path.root}/deployment"

  // The folder where is Dockerfile placed. If using relative path, it should
  // start from the deployment folder, as this directory will be mainly
  // used by the deployment scripts.
  docker_folder_relative_path = ".."

  // VPC the app are going to run on
  vpc_id = data.aws_vpc.default.id
  // Subnets for your tasks
  ecs_subnet_ids = data.aws_subnet_ids.private.ids
  // Subnets for the Load Balancer
  lb_subnet_ids = data.aws_subnet_ids.public.ids
  // lb_is_internal = true

  // Domain configuration
  route53_root_domain = var.root_domain
  route53_record_name = "test-api"
}
```
As described in the below topics, although most of the required AWS resources are automatically
created by this module, you should provide some required params in order to use it.
- `vpc_id` - The VPC Id the AWS resources will be attached to
- `vpc_subnet_ids` - The network subnets this architecture will be running
- `route53_root_domain` - Your hosted Route53's domain that will be used to create an `A Record` for your app

Aside from them, you should also provide:
- `app_name` - An identifier for this project. It should be unique once it will be used as prefix for AWS resources
- `app_version` - A unique version identifier for the application that will be deployed. Whenever this version changes, a new deployment will be automatically triggered.
- `docker_root_path` - The root folder to generate the Docker image. Usually the place where Dockerfile is located.

## Architecture Overview
This module leverages the following architecture in order to provide a reliable and easy
to maintain runtime environment for your microservices.
![zero downtime architecture - aws fargate and aws codedeploy-2](https://user-images.githubusercontent.com/521936/52188671-387ead00-2888-11e9-9bdc-f64a2f13c490.png)

#### Main goals
- Zero server maintenance in order to build and deploy new versions of an specific service
- Zero Downtime deployment
- Automatic rollback in case of failure
- Least possible dependency on third-party tools (relies only on AWS)
- Easy to reproduce/duplicate configuration

#### How it works?
This module expects that you have an application properly configured as Docker image, ready
to be deployed into a Docker register. It will take care of:

1. Creating a new AWS ECR's Docker Registry for your new service
1. Spinning up an AWS ECS cluster
1. Create an ECS task behind an AWS Application Load Balancer
1. Register an initial dummy application to run on your cluster
1. Create a CodeDeploy application to deploy your tasks
1. Create an SNS Topic so you can listen for deployment events
1. Create a CloudWatch Log Group to store logs from your App
1. Generate a script to deploy your Docker app as a task for this ECS service using CodeDeploy
1. Create a Route53 `DNS A Record` pointing the ALB

In order to leverage Zero Downtime deployment, it leans on a Blue Green deployment structure
backed by AWS CodeDeploy and AWS Application Load Balancer. By looking to the **green** _sequence
flows_ in the above picture you'll see how HTTPS requests are handled by the server. Basically:
1. Resolve the microservice's Load Balance FQDNS.
2. Points the request to the Load Balacer.
3. The Load Balancer pick an instance from the active (blue or green) Target Group to actually handle the request.

During a deployment, as we can see in the **purple** _sequence flows_, AWS CodeDeploy and AWS
Application Load Balancer interact each other, ensuring that the traffic is re-routed from the
blue to the green Target Group after a successful deployment.
1. Upload your new Docker image into the ECR.
2. Create and Deploy a task using your just uploaded ECR, and notify AWS CodeDeploy to start the deployment it self.
3. AWS CodeDeploy will notify AWS ECS in order to spin up instances as defined on your task file.
4. Once the tasks are running, all instances are registered into the green Target Group. If the health-check fails during the startup, the deployment is discarded and the instances are terminated.
5. AWS CodeDeploy will re-route all traffic to the new deployed instances, while previous instances will have their connections gracefully drained - ensuring all request were finished before destroy them.
