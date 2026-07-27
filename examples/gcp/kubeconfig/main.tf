module "bootstrap" {
  source = "../../../"

  k8s_provider   = "gcp"
  gcp_project_id = var.gcp_project_id

  platform             = var.platform
  github_auth          = var.github_auth
  cluster_registration = var.cluster_registration

  argocd_operator_helm_chart_version = "0.0.12"
  argocd_instance_helm_chart_version = "0.18.0"
  create_network_policies            = false
  enable_auto_sync                   = true
}
