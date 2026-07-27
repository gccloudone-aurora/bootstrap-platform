locals {
  # AppSet destination: registered cluster name when cluster_registration is set
  # (exactly one entry), otherwise Argo CD's built-in in-cluster destination.
  appset_destination_name = length(var.cluster_registration) == 0 ? "in-cluster" : one(keys(var.cluster_registration))

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
  repo_creds_url = var.github_auth.github_app != null ? coalesce(var.github_auth.github_app.creds_url, var.platform.git.url) : var.platform.git.url

  # argocd-instance chart register.repositoryCreds (GitHub App requires chart >= 0.18.0)
  repository_creds = var.github_auth.github_app != null ? {
    "project-aurora-mgmt-repo-creds" = {
      type = "git"
      url  = local.repo_creds_url
      githubApp = merge(
        {
          id             = var.github_auth.github_app.id
          installationID = var.github_auth.github_app.installation_id
          privateKey     = var.github_auth.github_app.private_key
        },
        var.github_auth.github_app.enterprise_base_url != null ? {
          enterpriseBaseUrl = var.github_auth.github_app.enterprise_base_url
        } : {}
      )
    }
  } : {
    "project-aurora-mgmt-repo-creds" = {
      type     = "git"
      url      = local.repo_creds_url
      username = var.github_auth.pat.username
      password = var.github_auth.pat.token
    }
  }
}

