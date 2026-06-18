resource "aws_db_subnet_group" "main" {
  name       = "${var.project_name}-db-subnet-group"
  subnet_ids = var.subnet_ids

  tags = {
    Name        = "${var.project_name}-db-subnet-group"
    Environment = var.environment
  }
}

resource "aws_db_instance" "main" {
  identifier              = "${var.project_name}-db"
  engine                  = var.engine
  engine_version          = var.engine_version
  instance_class          = var.instance_class
  allocated_storage       = var.allocated_storage
  storage_type            = "gp3"
  storage_encrypted       = true
  db_name                 = var.db_name
  username                = var.db_username
  password                = var.db_password
  db_subnet_group_name    = aws_db_subnet_group.main.name
  vpc_security_group_ids  = var.security_group_ids
  multi_az                = var.multi_az
  publicly_accessible     = false
  skip_final_snapshot     = var.skip_final_snapshot
  final_snapshot_identifier = var.skip_final_snapshot ? null : "${var.project_name}-final-snapshot"
  backup_retention_period = var.backup_retention_period
  deletion_protection     = var.deletion_protection

  tags = {
    Name        = "${var.project_name}-db"
    Environment = var.environment
  }
}
