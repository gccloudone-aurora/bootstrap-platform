variable "kubeconfig_path" {
  description = "Path to the kubeconfig file used by the kubernetes and helm providers."
  type        = string
  default     = "~/.kube/config"
}

variable "config_context" {
  description = "Kubernetes config context for the target AKS cluster."
  type        = string
}

variable "azure_client_id" {
  description = "Entra app / user-assigned managed identity client ID for Argo CD workload identity and AVP."
  type        = string
}

variable "platform" {
  description = "Platform git (and optional helm registry) sources for bootstrap."
  type = object({
    git = object({
      url    = string
      branch = optional(string, "main")
      path   = string
    })
    helm = optional(object({
      registry = optional(string, "https://gccloudone-aurora.github.io/aurora-platform-charts")
    }), {})
  })
}

variable "github_auth" {
  description = "Git credentials for Argo CD. Set exactly one of pat or github_app."
  type = object({
    pat = optional(object({
      username = string
      token    = string
    }))
    github_app = optional(object({
      id                  = string
      installation_id     = string
      private_key         = string
      enterprise_base_url = optional(string)
      creds_url           = optional(string)
    }))
  })
  sensitive = true

  validation {
    condition = (
      (var.github_auth.pat != null && var.github_auth.github_app == null) ||
      (var.github_auth.pat == null && var.github_auth.github_app != null)
    )
    error_message = "github_auth must set exactly one of pat or github_app."
  }
}

variable "cluster_registration" {
  description = "Optional register.clusters map (cluster name → server/token/caData). Empty means in-cluster only."
  type = map(object({
    server = string
    token  = string
    caData = string
  }))
  default   = {}
  sensitive = true
}
