# Create a service account along with RBAC for cluster registration.
#
# https://github.com/gccloudone-aurora-iac/terraform-kubernetes-cluster-register.git
#
module "argocd_cluster_sp" {
  source = "git::https://github.com/gccloudone-aurora-iac/terraform-kubernetes-cluster-register.git?ref=v1.0.0"

  service_account_name = "argocd-mgmt"
  namespace            = "platform-system"

  role_binding = {
    scope     = "cluster"
    role_name = "cluster-admin"
  }
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
    # "name"   = "cluster-bootstrap"
    "name" = var.cluster_name
    "server" = "https://kubernetes.default.svc.cluster.local"
    "config" = jsonencode({
      "bearerToken" = module.argocd_cluster_sp.service_account_token_secret.data.token
      "tlsClientConfig" = {
        "insecure" = false,
        "caData"   = base64encode(module.argocd_cluster_sp.service_account_token_secret.data["ca.crt"])
      }
    })
  }
}
