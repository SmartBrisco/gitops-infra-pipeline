output "instance_id" {
  description = "EC2 instance ID"
  value       = aws_instance.dev.id
}

output "instance_public_ip" {
  description = "EC2 instance public IP"
  value       = aws_instance.dev.public_ip
}

output "instance_state" {
  description = "EC2 instance state"
  value       = aws_instance.dev.instance_state
}

output "instance_type" {
  description = "EC2 instance type"
  value       = aws_instance.dev.instance_type
}

output "aws_region" {
  description = "AWS region deployed to"
  value       = var.aws_region
}

output "security_group_id" {
  description = "Security group ID"
  value       = aws_security_group.dev.id
}

output "eks_cluster_name" {
  value = aws_eks_cluster.main.name
}

output "eks_cluster_endpoint" {
  value = aws_eks_cluster.main.endpoint
}