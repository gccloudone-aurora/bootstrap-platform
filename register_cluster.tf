# Create a service account along with RBAC for cluster registration when
# cluster_registration credentials are not supplied by the caller.
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

# Mechanism to inject containers with sensitive information.
#
# https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/secret
#
resource "kubernetes_secret_v1" "cluster_bootstrap" {
  metadata {
    name      = var.cluster_name
    namespace = kubernetes_namespace_v1.platform_management_system.metadata[0].name
    labels = {
      "argocd.argoproj.io/secret-type" = "cluster"
    }
  }

  type = "Opaque"

  data = {
    "name"   = var.cluster_name
    "server" = "https://kubernetes.default.svc.cluster.local"
    "config" = jsonencode({
      "bearerToken" = local.cluster_registration_token
      "tlsClientConfig" = {
        "insecure" = false,
        "caData"   = base64encode(local.cluster_registration_ca_cert)
      }
    })
  }

  depends_on = [helm_release.argocd_instance]
}
