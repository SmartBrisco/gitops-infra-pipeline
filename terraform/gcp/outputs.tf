output "instance_name" {
  description = "GCP VM instance name"
  value       = var.deploy ? google_compute_instance.vm[0].name : "not deployed"
}

output "instance_self_link" {
  description = "GCP VM self link"
  value       = var.deploy ? google_compute_instance.vm[0].self_link : "not deployed"
}

output "network_name" {
  description = "GCP network name"
  value       = var.deploy ? google_compute_network.network[0].name : "not deployed"
}

output "gke_cluster_name" {
  value = var.deploy ? google_container_cluster.main[0].name : "not deployed"
}

output "gke_cluster_endpoint" {
  value = var.deploy ? google_container_cluster.main[0].endpoint : "not deployed"
}