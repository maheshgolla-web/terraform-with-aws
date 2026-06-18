data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_key_pair" "main" {
  count      = var.create_key_pair ? 1 : 0
  key_name   = "${var.project_name}-key"
  public_key = file(var.public_key_path)

  tags = {
    Name        = "${var.project_name}-key"
    Environment = var.environment
  }
}

resource "aws_instance" "this" {
  count                  = var.instance_count
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = var.instance_type
  subnet_id              = var.subnet_ids[count.index % length(var.subnet_ids)]
  vpc_security_group_ids = var.security_group_ids
  key_name               = var.create_key_pair ? aws_key_pair.main[0].key_name : var.key_name
  user_data              = var.user_data

  root_block_device {
    volume_size = var.volume_size
    volume_type = "gp3"
    encrypted   = true
  }

  tags = {
    Name        = "${var.project_name}-${var.instance_name}-${count.index + 1}"
    Environment = var.environment
    Role        = var.instance_name
  }
}
