output "alb_dns_name" {
  description = "DNS name of the load balancer — access your app here"
  value       = module.alb.alb_dns_name
}

output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "web_instance_ids" {
  description = "IDs of web EC2 instances"
  value       = module.web_ec2.instance_ids
}

output "web_private_ips" {
  description = "Private IPs of web EC2 instances"
  value       = module.web_ec2.private_ips
}

output "db_endpoint" {
  description = "RDS database endpoint"
  value       = module.rds.db_endpoint
}

output "db_name" {
  description = "Database name"
  value       = module.rds.db_name
}
