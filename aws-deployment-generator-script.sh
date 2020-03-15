#!/usr/bin/env bash
cd $(dirname $0)
DIR=$(pwd)
ENV=${1?"Environment not defined. Usage: $0 [ENV]"}
CONF=./${ENV}/conf.sh

## FUNCTIONS
info(){
  printf "\033[1;33m$@\e[m\n"
}

docker_package(){
  info "Building Docker image ${DOCKER_IMAGE}..."
  DOCKER_OPTS="--build-arg APP_NAME=${APP_NAME}"
  DOCKER_OPTS="$DOCKER_OPTS --build-arg ENVIRONMENT=${ENVIRONMENT}"
  if [ ! "${DOCKER_PARENT}" = "" ]; then
    DOCKER_OPTS="$DOCKER_OPTS --build-arg PARENT_IMAGE=${DOCKER_PARENT}"
  fi
  docker build -t "${DOCKER_IMAGE}" ${DOCKER_OPTS} ${DOCKER_FOLDER} || exit 2
}

docker_deploy(){
  info "Pushing Docker image ${DOCKER_IMAGE}..."
  docker push "${DOCKER_IMAGE}" || exit 2
}

codedeploy_deploy(){
  info "Notifying CodeDeploy about the new software revision..."
  aws ecs deploy \
    --region ${AWS_REGION} \
    --service ${ECS_SERVICE} \
    --cluster ${ECS_CLUSTER} \
    --task-definition "${ECS_FILE_TASK_DEF}" \
    --codedeploy-application ${ECS_DEPLOY_APP} \
    --codedeploy-deployment-group ${ECS_DEPLOY_GRP} \
    --codedeploy-appspec "${ECS_FILE_DEPLOY_SPEC}" || exit 2
}

## VARIABLES
if [ ! -f ${CONF} ]; then
    echo "Deployment not configured for env ${ENV}"
    echo "As this wrapper was generated automatically, please try to execute terraform deployment again."
    exit 2
else
    . ${CONF}
fi

AWS_REGION=${AWS_REGION?"Not defined"}
DOCKER_FOLDER=${DOCKER_FOLDER?"Not defined"}
DOCKER_IMAGE=${DOCKER_IMAGE?"Not defined"}
ECS_SERVICE=${ECS_SERVICE?"Not defined"}
ECS_CLUSTER=${ECS_CLUSTER?"Not defined"}
ECS_DEPLOY_APP=${ECS_DEPLOY_APP?"Not defined"}
ECS_DEPLOY_GRP=${ECS_DEPLOY_GRP?"Not defined"}
ECS_FILE_TASK_DEF=${ECS_FILE_TASK_DEF?"Not defined"}
ECS_FILE_DEPLOY_SPEC=${ECS_FILE_DEPLOY_SPEC?"Not defined"}
APP_NAME=${APP_NAME?"Not defined"}
ENVIRONMENT=${ENVIRONMENT?"Not defined"}

if [ -f ./deploy.custom ]; then
   . ./deploy.custom
fi

$(aws --region ${AWS_REGION} ecr get-login --no-include-email) && \
  docker_package && \
  docker_deploy && \
  codedeploy_deploy ||
  exit 3
