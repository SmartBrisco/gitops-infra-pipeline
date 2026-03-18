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

variable "azure_client_id" {
  description = "Azure client ID"
  type        = string
  default     = "00000000-0000-0000-0000-000000000000"
}

variable "azure_tenant_id" {
  description = "Azure tenant ID"
  type        = string
  default     = "00000000-0000-0000-0000-000000000000"
}

variable "azure_subscription_id" {
  description = "Azure subscription ID"
  type        = string
  default     = "00000000-0000-0000-0000-000000000000"
}

variable "azure_client_secret" {
  description = "Azure client secret"
  type        = string
  default     = "placeholder"
  sensitive   = true
}