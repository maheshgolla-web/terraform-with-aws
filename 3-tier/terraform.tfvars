aws_region   = "us-east-1"
project_name = "myapp"
environment  = "dev"

# VPC
vpc_cidr             = "10.0.0.0/16"
public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
private_subnet_cidrs = ["10.0.3.0/24", "10.0.4.0/24"]
availability_zones   = ["us-east-1a", "us-east-1b"]

# Web tier
web_instance_type  = "t2.micro"
web_instance_count = 2
volume_size        = 20

# App tier
app_instance_type  = "t2.micro"
app_instance_count = 2

# RDS
db_instance_class = "db.t3.micro"
db_storage        = 20
db_name           = "appdb"
db_username       = "admin"
db_password       = "YourStrongPassword123!"
multi_az          = false
