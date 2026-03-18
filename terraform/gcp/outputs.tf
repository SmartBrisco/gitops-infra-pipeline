output "instance_name" {
  description = "GCP VM instance name"
  value       = var.deploy ? google_compute_instance.vm[0].name : "not deployed"
}

output "instance_self_link" {
  description = "GCP VM self link"
  value       = var.deploy ? google_compute_instance.vm[0].self_link : "not deployed"
}

output "network_name" {
  description = "VPC network name"
  value       = var.deploy ? google_compute_network.vpc[0].name : "not deployed"
}