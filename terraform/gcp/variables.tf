variable "project_id" {
  description = "GCP project ID"
  type        = string
  default     = "demo-project"
}

variable "region" {
  description = "GCP region"
  type        = string
  default     = "us-central1"
}

variable "zone" {
  description = "GCP zone"
  type        = string
  default     = "us-central1-a"
}

variable "deploy" {
  description = "Set to true to actually provision resources"
  type        = bool
  default     = false
}