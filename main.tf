provider "aws" {
  region = "us-east-1"
}
data "aws_region" "current" {}

module "vpc" {
  source = "./modules/vpc"
}

module "security" {
  source       = "./modules/security"
  project_name = var.project_name
  vpc_id       = module.vpc.vpc_id
}

module "alb" {
  source         = "./modules/alb"
  project_name   = var.project_name
  vpc_id         = module.vpc.vpc_id
  alb_sg_id      = module.security.alb_sg_id
  public_subnets = [module.vpc.public_subnet_1_id, module.vpc.public_subnet_2_id]
}


module "ecs" {
  source             = "./modules/ecs"
  project_name       = var.project_name
  aws_region         = data.aws_region.current.name
  execution_role_arn = aws_iam_role.ecs_execution_role.arn
  task_role_arn      = aws_iam_role.ecs_task_role.arn

  public_subnet_2_id = module.vpc.public_subnet_2_id
  fargate_sg_id      = module.security.fargate_sg_id

  target_group_arn   = module.alb.target_group_arn

  depends_on = [module.alb]
}
