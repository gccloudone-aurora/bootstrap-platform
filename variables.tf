variable "k8s_provider" {
  description = "The platform upon which Kubernetes is deployed. Currently can be 'azure' or 'gcp'"
  validation {
    condition = contains(["azure", "gcp"], var.k8s_provider)
    error_message = "The k8s provider must be one of 'azure' or 'gcp'"
  }
}

### AZURE ###

variable "client_id" {
  description = "The Workload Identity Client ID. Set if bootstrapping for Azure."
  default = ""
}

### GCP ###
variable "gcp_project_id" {
  description = "The GCP project ID where the management cluster is deployed."
  default = ""
}

variable "cluster_name" {
  description = "The name of the kubernetes cluster. Used for setting up the initial cluster secret for ArgoCD registration."
}

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
