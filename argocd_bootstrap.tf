locals {
  bootstrap_chart = "${path.module}/charts/argocd-bootstrap"
  bootstrap_chart_revision = sha256(jsonencode([
    for path in sort(fileset(local.bootstrap_chart, "**")) :
    filesha256("${local.bootstrap_chart}/${path}")
  ]))
}

resource "helm_release" "argocd_crds" {
  name        = "argocd-crds"
  chart       = local.bootstrap_chart
  namespace   = kubernetes_namespace_v1.platform_management_system.metadata[0].name
  atomic      = true
  timeout     = 900
  max_history = 2

  values = [yamlencode({
    phase         = "readiness"
    chartRevision = local.bootstrap_chart_revision
    readiness = {
      image = var.crd_wait_image
    }
  })]

  depends_on = [helm_release.argocd_instance]
}

resource "helm_release" "argocd_bootstrap" {
  name        = "argocd-bootstrap"
  chart       = local.bootstrap_chart
  namespace   = kubernetes_namespace_v1.platform_management_system.metadata[0].name
  atomic      = true
  timeout     = 600
  max_history = 2

  values = [yamlencode({
    phase         = "resources"
    chartRevision = local.bootstrap_chart_revision
    automation = {
      enabled = var.application_auto_sync
    }
    permissions = {
      sourceRepos = coalesce(var.project_permissions.source_repositories, [
        var.github_url,
        "https://gccloudone-aurora.github.io/aurora-platform-charts",
      ])
      destinations             = var.project_permissions.destinations
      clusterResourceWhitelist = var.project_permissions.cluster_resources
    }
    git = {
      url    = var.github_url
      branch = var.github_branch
      path   = var.github_path
    }
  })]

  depends_on = [
    helm_release.argocd_crds,
    kubernetes_secret_v1.cluster_bootstrap,
    kubernetes_secret_v1.project_aurora_mgmt,
    kubernetes_secret_v1.project_aurora_mgmt_repo_creds,
  ]
}
