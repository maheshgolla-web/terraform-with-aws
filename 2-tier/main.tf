terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  required_version = ">= 1.0"
}

provider "aws" {
  region = var.aws_region
}

# ─── VPC ───────────────────────────────────────────────────
module "vpc" {
  source = "../modules/vpc"

  project_name         = var.project_name
  environment          = var.environment
  vpc_cidr             = var.vpc_cidr
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  availability_zones   = var.availability_zones
}

# ─── Security Groups ───────────────────────────────────────

# ALB security group — allow HTTP from internet
module "alb_sg" {
  source = "../modules/security_group"

  project_name = var.project_name
  environment  = var.environment
  sg_name      = "alb"
  description  = "Security group for ALB"
  vpc_id       = module.vpc.vpc_id

  ingress_rules = [
    {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
      description = "HTTP from internet"
    }
  ]
}

# Web EC2 security group — allow HTTP from ALB only
module "web_sg" {
  source = "../modules/security_group"

  project_name = var.project_name
  environment  = var.environment
  sg_name      = "web"
  description  = "Security group for web EC2 instances"
  vpc_id       = module.vpc.vpc_id

  ingress_rules = [
    {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = [var.vpc_cidr]
      description = "HTTP from ALB"
    },
    {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
      description = "SSH access"
    }
  ]
}

# RDS security group — allow MySQL from web EC2 only
module "db_sg" {
  source = "../modules/security_group"

  project_name = var.project_name
  environment  = var.environment
  sg_name      = "db"
  description  = "Security group for RDS database"
  vpc_id       = module.vpc.vpc_id

  ingress_rules = [
    {
      from_port   = 3306
      to_port     = 3306
      protocol    = "tcp"
      cidr_blocks = [var.vpc_cidr]
      description = "MySQL from web tier"
    }
  ]
}

# ─── Web EC2 Instances ────────────────────────────────────
module "web_ec2" {
  source = "../modules/ec2"

  project_name       = var.project_name
  environment        = var.environment
  instance_name      = "web"
  instance_type      = var.web_instance_type
  instance_count     = var.web_instance_count
  subnet_ids         = module.vpc.public_subnet_ids
  security_group_ids = [module.web_sg.security_group_id]
  volume_size        = var.volume_size
}

# ─── ALB ──────────────────────────────────────────────────
module "alb" {
  source = "../modules/alb"

  project_name       = var.project_name
  environment        = var.environment
  vpc_id             = module.vpc.vpc_id
  subnet_ids         = module.vpc.public_subnet_ids
  security_group_ids = [module.alb_sg.security_group_id]
  instance_ids       = module.web_ec2.instance_ids
  target_port        = 80
  health_check_path  = "/"
}

# ─── RDS Database ─────────────────────────────────────────
module "rds" {
  source = "../modules/rds"

  project_name       = var.project_name
  environment        = var.environment
  subnet_ids         = module.vpc.private_subnet_ids
  security_group_ids = [module.db_sg.security_group_id]
  engine             = "mysql"
  engine_version     = "8.0"
  instance_class     = var.db_instance_class
  allocated_storage  = var.db_storage
  db_name            = var.db_name
  db_username        = var.db_username
  db_password        = var.db_password
  multi_az           = var.multi_az
}
