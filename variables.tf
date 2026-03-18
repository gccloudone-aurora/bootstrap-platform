variable "client_id" {
  description = "The Workload Identity Client ID"
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
