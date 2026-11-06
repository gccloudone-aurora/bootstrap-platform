variable "k8s_provider" {
  description = "The Kubernetes platform: azure, gcp, or openstack. OpenStack disables the vault plugin until a secrets backend is configured."
  type        = string
  validation {
    condition     = contains(["azure", "gcp", "openstack"], var.k8s_provider)
    error_message = "The k8s provider must be one of 'azure', 'gcp', or 'openstack'."
  }
}

### AZURE ###

variable "client_id" {
  description = "The Workload Identity Client ID. Set if bootstrapping for Azure."
  type        = string
  default     = ""
}

### GCP ###
variable "gcp_project_id" {
  description = "The GCP project ID where the management cluster is deployed."
  type        = string
  default     = ""
}

variable "cluster_name" {
  description = "The name of the kubernetes cluster. Used for setting up the initial cluster secret for ArgoCD registration."
  type        = string
}

variable "config_context" {
  description = "The Kubernetes config context"
  type        = string
}

variable "config_path" {
  description = "Path to the kubeconfig used by the Kubernetes and Helm providers."
  type        = string
  default     = "~/.kube/config"
}

variable "crd_wait_image" {
  description = "Pinned kubectl image used by the in-cluster CRD readiness job. Use a client version compatible with the target cluster."
  type        = string
  default     = "registry.k8s.io/kubectl:v1.36.3"
}

variable "github_token" {
  description = "The GitHub token for the project repository."
  type        = string

  sensitive = true
}

variable "github_username" {
  description = "The GitHub username for the project repository."
  type        = string
}

variable "github_url" {
  description = "The GitHub url for the project repository."
  type        = string
}

variable "github_branch" {
  description = "The GitHub branch for the project repository."
  type        = string
}

variable "github_path" {
  description = "The GitHub path for the config.yaml file in the project repository."
  type        = string
}

variable "application_auto_sync" {
  description = "Enable automatic self-healing sync only after reviewing generated applications. Pruning remains disabled."
  type        = bool
  default     = false
}

variable "project_permissions" {
  description = "Explicit AppProject repository, destination, and cluster-resource allowlists. Null repositories use the configured Git repository and platform chart repository."
  type = object({
    source_repositories = optional(list(string))
    destinations = optional(list(object({
      server    = string
      namespace = string
      })), [
      { server = "https://kubernetes.default.svc", namespace = "*" },
      { server = "https://kubernetes.default.svc.cluster.local", namespace = "*" },
    ])
    cluster_resources = optional(list(object({
      group = string
      kind  = string
    })), [{ group = "*", kind = "*" }])
  })
  default  = {}
  nullable = false

  validation {
    condition     = length(var.project_permissions.destinations) > 0
    error_message = "At least one explicit destination must be configured."
  }
}

variable "sso" {
  description = "Optional Entra OIDC settings supported by the pinned instance chart. Leave disabled until the application and group claims are configured."
  type = object({
    enabled         = optional(bool, false)
    tenant_id       = optional(string, "")
    client_id       = optional(string, "")
    client_secret   = optional(string, "")
    admin_group     = optional(string, "")
    disable_admin   = optional(bool, false)
    access_verified = optional(bool, false)
  })
  default   = {}
  sensitive = true
  nullable  = false

  validation {
    condition = !var.sso.enabled || alltrue([
      for value in [var.sso.tenant_id, var.sso.client_id, var.sso.client_secret, var.sso.admin_group] :
      length(trimspace(value)) > 0
    ])
    error_message = "Enabling SSO requires tenant ID, client ID, client secret, and an admin group."
  }

  validation {
    condition     = !var.sso.disable_admin || (var.sso.enabled && var.sso.access_verified)
    error_message = "Disable local admin only after SSO is enabled and group access has been verified."
  }
}

variable "argocd_resources" {
  description = "Optional resource-budget overrides for controller, repo, server, redis, and applicationSet."
  type = map(object({
    requests = map(string)
    limits   = map(string)
  }))
  default = {}

  validation {
    condition = alltrue([
      for component, budget in var.argocd_resources :
      contains(["controller", "repo", "server", "redis", "applicationSet"], component) &&
      can(budget.requests.cpu) && can(budget.requests.memory) &&
      can(budget.limits.cpu) && can(budget.limits.memory)
    ])
    error_message = "Each supported component must specify CPU and memory requests and limits."
  }
}

variable "argocd_server_service_type" {
  description = "Server Service type. Configure trusted ingress and TLS before exposing it beyond port-forward access."
  type        = string
  default     = "ClusterIP"

  validation {
    condition     = contains(["ClusterIP", "NodePort", "LoadBalancer"], var.argocd_server_service_type)
    error_message = "Server service type must be ClusterIP, NodePort, or LoadBalancer."
  }
}

variable "argocd_chart_versions" {
  description = "Exact operator and instance chart versions. Validate rendered values and compatibility before upgrading."
  type = object({
    operator = string
    instance = string
  })
  default = {
    operator = "0.0.13"
    instance = "0.27.0"
  }

  validation {
    condition     = alltrue([for version in values(var.argocd_chart_versions) : can(regex("^[0-9]+\\.[0-9]+\\.[0-9]+(-[0-9A-Za-z.-]+)?$", version))])
    error_message = "Chart versions must be exact versions, not version ranges."
  }
}

variable "argocd_service_monitor_enabled" {
  description = "Create ServiceMonitor resources only when Prometheus Operator and its CRDs are already installed."
  type        = bool
  default     = false
}
