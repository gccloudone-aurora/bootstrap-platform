variable "project_id" {
  description = "GCP project ID where the VPC and GKE cluster are created"
  type        = string
}

variable "region" {
  description = "GCP region for the GKE cluster"
  type        = string
  default     = "northamerica-northeast1"
}
