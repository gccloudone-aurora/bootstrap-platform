# AppProjects, ApplicationSet, NetworkPolicies, and Cilium CCNPs.
# Applied via Helm so CRDs created by argocd-instance are not required at plan time
# (kubernetes_manifest contacts the API for OpenAPI schema during plan).
resource "helm_release" "bootstrap_manifests" {
  name             = "bootstrap-manifests"
  chart            = "${path.module}/charts/bootstrap-manifests"
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
        githubPath   = var.platform_git_repository.path
        githubUrl    = var.platform_git_repository.url
        githubBranch = var.platform_git_repository.branch
        helmRegistry = var.helm_registry
      }
      networkPolicies = var.create_network_policies
      clusterwideNetworkPolicies = {
        apiserverEgress = var.create_network_policies
        gcpCoreDns      = var.create_network_policies && var.k8s_provider == "gcp"
        cspMetadata     = var.create_network_policies && contains(["azure", "gcp"], var.k8s_provider)
        awsCoreDns      = var.create_network_policies && var.k8s_provider == "aws"
        awsMetadata     = var.create_network_policies && var.k8s_provider == "aws"
      }
    })
  ]

  depends_on = [helm_release.argocd_instance]
}
