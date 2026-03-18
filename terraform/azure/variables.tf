variable "location" {
  description = "Azure region"
  type        = string
  default     = "East US"
}

variable "resource_group_name" {
  description = "Name of the Azure resource group"
  type        = string
  default     = "gitops-infra-rg"
}

variable "deploy" {
  description = "Set to true to actually provision resources"
  type        = bool
  default     = false
}

variable "ssh_public_key" {
  description = "SSH public key for VM admin user"
  type        = string
  default     = ""
}