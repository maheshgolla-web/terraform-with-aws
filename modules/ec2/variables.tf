variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "instance_name" {
  description = "Name tag for the instance"
  type        = string
  default     = "web"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.micro"
}

variable "instance_count" {
  description = "Number of instances to create"
  type        = number
  default     = 1
}

variable "subnet_ids" {
  description = "Subnet IDs where instances will be created"
  type        = list(string)
}

variable "security_group_ids" {
  description = "Security group IDs to attach to instances"
  type        = list(string)
}

variable "volume_size" {
  description = "Root volume size in GB"
  type        = number
  default     = 20
}

variable "create_key_pair" {
  description = "Whether to create a new key pair"
  type        = bool
  default     = false
}

variable "public_key_path" {
  description = "Path to public key file"
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}

variable "key_name" {
  description = "Existing key pair name"
  type        = string
  default     = ""
}

variable "user_data" {
  description = "User data script to run on instance launch"
  type        = string
  default     = <<-EOF
    #!/bin/bash
    yum update -y
    yum install -y httpd
    systemctl start httpd
    systemctl enable httpd
    echo "<h1>Hello from $(hostname)</h1>" > /var/www/html/index.html
  EOF
}
