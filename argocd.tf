# A Release is an instance of a helm chart.
#
# https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release
#
resource "helm_release" "argo_operator" {
  name            = "argo-operator"
  repository      = var.helm_registry
  chart           = "argocd-operator"
  namespace       = kubernetes_namespace_v1.argo_operator_system.metadata[0].name
  atomic          = true
  upgrade_install = true
  max_history     = 2
  version         = var.argocd_operator_helm_chart_version

  set = [
    {
      name  = "operator.nsToWatch"
      value = ""
    },
    {
      name  = "operator.nsClusterConfig"
      value = kubernetes_namespace_v1.platform_management_system.metadata[0].name
    }
  ]
}

locals {
  # Add new configurations as bootstrap is developed
  argocd_values = {
    aws = {
      argocdVaultPlugin = {
        env = {
          # Secrets Manager access via EKS Pod Identity (caller-managed association)
          ARGOCD_ENV_AVP_TYPE = "awssecretsmanager"
        }
      }
    }
    azure = {
      repo = {
        labels = {
          "azure.workload.identity/use" = "true"
        },
        serviceAccountAnnotations = {
          "azure.workload.identity/client-id" = var.azure_client_id
        }
      }
      argocdVaultPlugin = {
        env = {
          ARGOCD_ENV_AVP_TYPE        = "azurekeyvault"
          ARGOCD_ENV_AZURE_CLIENT_ID = var.azure_client_id
        }
      }
    }
    gcp = {
      repo = {
        serviceAccountAnnotations = {
          "iam.gke.io/gcp-service-account" = "argocd-repo-server@${var.gcp_project_id}.iam.gserviceaccount.com"
        }
      }
      argocdVaultPlugin = {
        env = {
          ARGOCD_ENV_AVP_TYPE = "gcpsecretmanager"
        }
      }
    }
  }

  github_app = try(var.github_auth.github_app, null)
  github_pat = try(var.github_auth.pat, null)

  repo_creds_url = local.github_app != null ? coalesce(local.github_app.creds_url, var.platform_git_repository.url) : var.platform_git_repository.url

  # argocd-instance chart register.repositoryCreds (GitHub App requires chart >= 0.18.0)
  repository_creds = local.github_app != null ? {
    "project-aurora-mgmt-repo-creds" = {
      type = "git"
      url  = local.repo_creds_url
      githubApp = merge(
        {
          id             = local.github_app.id
          installationID = local.github_app.installation_id
          privateKey     = local.github_app.private_key
        },
        local.github_app.enterprise_base_url != null ? {
          enterpriseBaseUrl = local.github_app.enterprise_base_url
        } : {}
      )
    }
  } : {
    "project-aurora-mgmt-repo-creds" = {
      type     = "git"
      url      = local.repo_creds_url
      username = local.github_pat.username
      password = local.github_pat.token
    }
  }
}

resource "helm_release" "argocd_instance" {
  name            = "argocd-instance"
  repository      = var.helm_registry
  chart           = "argocd-instance"
  namespace       = kubernetes_namespace_v1.platform_management_system.metadata[0].name
  atomic          = true
  upgrade_install = true
  max_history     = 2
  force_update    = true
  version         = var.argocd_instance_helm_chart_version

  values = [
    yamlencode({
      argocdInstance = local.argocd_values[var.k8s_provider]
      register = {
        clusters = {
          (var.cluster_name) = {
            server = "https://kubernetes.default.svc.cluster.local"
            token  = local.cluster_registration_token
            caData = base64encode(local.cluster_registration_ca_cert)
          }
        }
        repositories = {
          "project-aurora-mgmt" = {
            type = "git"
            url  = var.platform_git_repository.url
          }
        }
        repositoryCreds = local.repository_creds
      }
    })
  ]

  depends_on = [helm_release.argo_operator]
}
