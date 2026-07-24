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
}

locals {
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