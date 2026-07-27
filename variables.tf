#################
## Cloud / CSP ##
#################

variable "k8s_provider" {
  description = "Cloud where the management cluster runs: aws, azure, or gcp."
  type        = string

  validation {
    condition     = contains(["aws", "azure", "gcp"], var.k8s_provider)
    error_message = "The k8s provider must be one of 'aws', 'azure', or 'gcp'."
  }
}

variable "azure_client_id" {
  description = <<-EOT
    Azure only (required when k8s_provider = "azure"; leave empty for aws/gcp).
    Entra application (or user-assigned managed identity) client ID used by Argo CD:
      - annotates the repo-server service account (azure.workload.identity/client-id)
      - sets ARGOCD_ENV_AZURE_CLIENT_ID for AVP → Azure Key Vault
  EOT
  type        = string
  default     = ""

  validation {
    condition     = var.k8s_provider != "azure" || length(var.azure_client_id) > 0
    error_message = "azure_client_id is required when k8s_provider is \"azure\"."
  }
}

variable "gcp_project_id" {
  description = <<-EOT
    GCP only (required when k8s_provider = "gcp"; leave empty for aws/azure).
    GCP project ID that owns the Workload Identity GSA bound to Argo CD repo-server.
    Used to annotate the SA as: argocd-repo-server@<gcp_project_id>.iam.gserviceaccount.com
  EOT
  type        = string
  default     = ""

  validation {
    condition     = var.k8s_provider != "gcp" || length(var.gcp_project_id) > 0
    error_message = "gcp_project_id is required when k8s_provider is \"gcp\"."
  }
}

######################
## Platform sources ##
######################

variable "platform" {
  description = <<-EOT
    Platform sources:
      - git: ApplicationSet generator and Argo CD repository secret (cluster config.yaml files)
      - helm: chart repository used to install Argo CD charts and as AppSet chart repoURL
  EOT
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
  description = <<-EOT
    Git credentials for Argo CD repo-creds. Provide exactly one of:
      - pat: HTTPS username + personal access token (or fine-grained token)
      - github_app: GitHub App ID, installation ID, and PEM private key
    For github_app, set creds_url to an org/user URL prefix (e.g. https://github.com/my-org)
    so credentials apply to all repos under that prefix; defaults to platform.git.url.
  EOT
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

##########################
## Cluster registration ##
##########################

variable "cluster_registration" {
  description = <<-EOT
    Optional Argo CD cluster secrets passed through to argocd-instance
    register.clusters. Map key is the cluster name (and the AppSet
    destination.name). When empty (default), Applications use the built-in
    in-cluster destination. When set, provide exactly one entry — that key
    becomes the aurora-platform ApplicationSet destination.
    Caller must supply credentials (this module does not create an argocd-mgmt SA).
  EOT
  type = map(object({
    server = string
    token  = string
    caData = string
  }))
  default   = {}
  sensitive = true
}

####################
## Argo CD charts ##
####################

variable "argocd_operator_helm_chart_version" {
  description = "Version of the argocd-operator Helm chart."
  type        = string
  default     = "0.0.12"
}

variable "argocd_instance_helm_chart_version" {
  description = "Version of the argocd-instance Helm chart. Use >= 0.18.0 for GitHub App repositoryCreds."
  type        = string
  default     = "0.18.0"
}

###############
## Behaviour ##
###############

variable "create_network_policies" {
  description = "When true, create Kubernetes NetworkPolicies and CiliumClusterwideNetworkPolicies for Argo CD / platform namespaces. Set false to skip all network policy resources."
  type        = bool
  default     = false
}

variable "enable_auto_sync" {
  description = <<-EOT
    When true, ApplicationSet-generated Applications use automated sync (selfHeal)
    and AppProjects have no sync windows (syncs always allowed). When false,
    Applications require manual sync and AppProjects get a deny-all sync window
    that still permits manualSync.
  EOT
  type        = bool
  default     = true
}
