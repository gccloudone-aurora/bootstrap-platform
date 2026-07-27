# AppProjects, ApplicationSet, NetworkPolicies, and Cilium CCNPs.
# Applied via Helm so CRDs created by argocd-instance are not required at plan time
# (kubernetes_manifest contacts the API for OpenAPI schema during plan).
resource "helm_release" "bootstrap_aurora_platform" {
  name             = "bootstrap-aurora-platform"
  chart            = "${path.module}/charts/bootstrap-aurora-platform"
  namespace        = kubernetes_namespace_v1.platform_management_system.metadata[0].name
  create_namespace = false
  atomic           = true
  wait             = true
  timeout          = 300
  max_history      = 2

  values = [
    yamlencode({
      namespace      = kubernetes_namespace_v1.platform_management_system.metadata[0].name
      enableAutoSync = var.enable_auto_sync
      appProjects = [
        {
          name        = "aurora"
          description = "App Project for Aurora Platform"
        },
        {
          name        = "aurora-core"
          description = "App Project for Aurora Core"
        },
        {
          name        = "aurora-app"
          description = "App Project for Aurora App"
        }
      ]
      appSet = {
        githubPath      = var.platform.git.path
        githubUrl       = var.platform.git.url
        githubBranch    = var.platform.git.branch
        helmRegistry    = var.platform.helm.registry
        destinationName = local.appset_destination_name
      }
      networkPolicies = var.create_network_policies
      k8sProvider     = var.k8s_provider
      clusterwideNetworkPolicies = {
        apiserverEgress = var.create_network_policies
        coreDns         = var.create_network_policies
        metadata        = var.create_network_policies
      }
    })
  ]

  depends_on = [helm_release.argocd_instance]
}
