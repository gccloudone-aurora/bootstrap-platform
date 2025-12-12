resource "helm_release" "argo_operator" {
  name            = "argo-operator"
  repository      = "https://gccloudone-aurora.github.io/aurora-platform-charts"
  chart           = "argocd-operator"
  namespace       = kubernetes_namespace_v1.argo_operator_system.metadata[0].name
  atomic          = true
  upgrade_install = true   
  max_history     = 2

  set = [
    {
      name  = "operator.nsToWatch"
      value = ""
    },
    {
      name  = "operator.nsClusterConfig"
      value = "platform-management-system"
    }
  ]
}

resource "helm_release" "argocd_instance" {
  name            = "argocd-instance"
  repository      = "https://gccloudone-aurora.github.io/aurora-platform-charts"
  chart           = "argocd-instance"
  namespace       = kubernetes_namespace_v1.argo_operator_system.metadata[0].name
  atomic          = true
  upgrade_install = true   
  max_history     = 2
  force_update    = true
  version         = "0.3.0"
  set             = []
}
