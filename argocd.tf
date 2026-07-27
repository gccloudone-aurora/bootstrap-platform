# A Release is an instance of a helm chart.
#
# https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release
#
resource "helm_release" "argo_operator" {
  name            = "argo-operator"
  repository      = var.platform.helm.registry
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

resource "helm_release" "argocd_instance" {
  name            = "argocd-instance"
  repository      = var.platform.helm.registry
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
        clusters = var.cluster_registration
        repositories = {
          "project-aurora-mgmt" = {
            type = "git"
            url  = var.platform.git.url
          }
        }
        repositoryCreds = local.repository_creds
      }
    })
  ]

  depends_on = [helm_release.argo_operator]
}
