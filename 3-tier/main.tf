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

# Web tier security group — allow HTTP from ALB only
module "web_sg" {
  source = "../modules/security_group"

  project_name = var.project_name
  environment  = var.environment
  sg_name      = "web"
  description  = "Security group for web tier"
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

# App tier security group — allow from web tier only
module "app_sg" {
  source = "../modules/security_group"

  project_name = var.project_name
  environment  = var.environment
  sg_name      = "app"
  description  = "Security group for app tier"
  vpc_id       = module.vpc.vpc_id

  ingress_rules = [
    {
      from_port   = 8080
      to_port     = 8080
      protocol    = "tcp"
      cidr_blocks = [var.vpc_cidr]
      description = "App port from web tier"
    },
    {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = [var.vpc_cidr]
      description = "SSH from web tier"
    }
  ]
}

# DB tier security group — allow MySQL from app tier only
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
      description = "MySQL from app tier"
    }
  ]
}

# ─── Web Tier EC2 ─────────────────────────────────────────
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

  user_data = <<-EOF
    #!/bin/bash
    yum update -y
    yum install -y httpd
    systemctl start httpd
    systemctl enable httpd
    echo "<h1>Web Tier - $(hostname)</h1>" > /var/www/html/index.html
  EOF
}

# ─── App Tier EC2 ─────────────────────────────────────────
module "app_ec2" {
  source = "../modules/ec2"

  project_name       = var.project_name
  environment        = var.environment
  instance_name      = "app"
  instance_type      = var.app_instance_type
  instance_count     = var.app_instance_count
  subnet_ids         = module.vpc.private_subnet_ids
  security_group_ids = [module.app_sg.security_group_id]
  volume_size        = var.volume_size

  user_data = <<-EOF
    #!/bin/bash
    yum update -y
    yum install -y java-11-amazon-corretto
    echo "App tier ready on $(hostname)" > /tmp/app.log
  EOF
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
