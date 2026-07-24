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
    })
  ]

  depends_on = [helm_release.argo_operator]
}
