output "vm_name" {
  description = "Azure VM name"
  value       = var.deploy ? azurerm_linux_virtual_machine.vm[0].name : "not deployed"
}

output "vm_private_ip" {
  description = "Azure VM private IP"
  value       = var.deploy ? azurerm_network_interface.nic[0].private_ip_address : "not deployed"
}

output "resource_group_name" {
  description = "Resource group name"
  value       = var.deploy ? azurerm_resource_group.rg[0].name : "not deployed"
}

output "aks_cluster_name" {
  value = var.deploy ? azurerm_kubernetes_cluster.main[0].name : "not deployed"
}

output "aks_cluster_endpoint" {
  value = var.deploy ? azurerm_kubernetes_cluster.main[0].kube_config[0].host : "not deployed"
}