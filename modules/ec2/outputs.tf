output "instance_ids" {
  description = "IDs of the EC2 instances"
  value       = aws_instance.this[*].id
}

output "private_ips" {
  description = "Private IP addresses of the instances"
  value       = aws_instance.this[*].private_ip
}

output "public_ips" {
  description = "Public IP addresses of the instances"
  value       = aws_instance.this[*].public_ip
}
