# A Release is an instance of a helm chart.
#
# https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release
#
resource "helm_release" "argo_operator" {
  name            = "argo-operator"
  repository      = "https://gccloudone-aurora.github.io/aurora-platform-charts"
  chart           = "argocd-operator"
  namespace       = kubernetes_namespace_v1.argo_operator_system.metadata[0].name
  atomic          = true
  upgrade_install = true
  max_history     = 2
  version         = "0.0.12"

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

# A Release is an instance of a helm chart.
#
# https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release
#
resource "helm_release" "argocd_instance" {
  name            = "argocd-instance"
  repository      = "https://gccloudone-aurora.github.io/aurora-platform-charts"
  chart           = "argocd-instance"
  namespace       = kubernetes_namespace_v1.platform_management_system.metadata[0].name
  atomic          = true
  upgrade_install = true
  max_history     = 2
  force_update    = true
  version         = "0.15.0"

  values = [
    yamlencode({
      argocdInstance = {
        # repo = {
        #   labels = {
        #     "azure.workload.identity/use" = "true"
        #   },
        #   serviceAccountAnnotations = {
        #     "azure.workload.identity/client-id" = var.client_id
        #   }
        # }
        # argocdVaultPlugin = {
        #   env = {
        #     ARGOCD_ENV_AVP_TYPE       = "azurekeyvault"
        #     ARGOCD_ENV_AZURE_CLIENT_ID = var.client_id
        #   }
        # }

        ### GCP
        repo = {
          serviceAccountAnnotations = {
            "iam.gke.io/gcp-service-account" = "argocd-repo-server@${var.gcp_project_id}.iam.gserviceaccount.com"     # If using GSA to KSA binding
          }
        }
        argocdVaultPlugin = {
          env = {
            ARGOCD_ENV_AVP_TYPE       = "gcpsecretmanager"
          }
        }
      }
    })
  ]

  depends_on = [helm_release.argo_operator]
}
