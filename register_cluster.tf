# Create a service account along with RBAC for cluster registration when
# cluster_registration credentials are not supplied by the caller.
# The Argo CD cluster secret itself is rendered by the argocd-instance chart
# (register.clusters) from these locals.
#
# https://github.com/gccloudone-aurora-iac/terraform-kubernetes-cluster-register.git
#
module "argocd_cluster_sp" {
  count  = var.cluster_registration == null ? 1 : 0
  source = "git::https://github.com/gccloudone-aurora-iac/terraform-kubernetes-cluster-register.git?ref=v1.0.0"

  service_account_name = "argocd-mgmt"
  namespace            = kubernetes_namespace_v1.platform_system[0].metadata[0].name

  role_binding = {
    scope     = "cluster"
    role_name = "cluster-admin"
  }

  depends_on = [kubernetes_namespace_v1.platform_system]
}

locals {
  cluster_registration_token = coalesce(
    try(var.cluster_registration.token, null),
    try(module.argocd_cluster_sp[0].service_account_token_secret.data.token, null)
  )
  cluster_registration_ca_cert = coalesce(
    try(var.cluster_registration.ca_cert, null),
    try(module.argocd_cluster_sp[0].service_account_token_secret.data["ca.crt"], null)
  )
}
