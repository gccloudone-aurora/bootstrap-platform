variable "client_id" {
  description = "The Workload Identity Client ID. Set if bootstrapping for Azure."
  default = ""
}

variable "gcp_project_id" {
  description = "The GCP project ID where the management cluster is deployed."
  default = ""
}

variable "cluster_name" {
  
}
variable "gke_control_plane_ip" {}

variable "config_context" {
  description = "The Kubernetes config context"
}

variable "github_token" {
  description = "The GitHub token for the project repository."

  sensitive = true
}

variable "github_username" {
  description = "The GitHub username for the project repository."
}

variable "github_url" {
  description = "The GitHub url for the project repository."
}

variable "github_branch" {
  description = "The GitHub branch for the project repository."
}

variable "github_path" {
  description = "The GitHub path for the config.yaml file in the project repository."
}
