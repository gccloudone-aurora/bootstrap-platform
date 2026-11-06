resource "kubernetes_service_account_v1" "argocd_registration" {
  metadata {
    name      = "argocd-mgmt"
    namespace = kubernetes_namespace_v1.platform_system.metadata[0].name
  }

  lifecycle {
    ignore_changes = [image_pull_secret]
  }
}

resource "kubernetes_secret_v1" "argocd_registration_token" {
  metadata {
    name      = "argocd-mgmt-token"
    namespace = kubernetes_namespace_v1.platform_system.metadata[0].name
    annotations = {
      "kubernetes.io/service-account.name" = kubernetes_service_account_v1.argocd_registration.metadata[0].name
    }
  }

  type                           = "kubernetes.io/service-account-token"
  wait_for_service_account_token = true
}

resource "kubernetes_cluster_role_binding_v1" "argocd_registration" {
  metadata {
    name = "argocd-mgmt"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "cluster-admin"
  }
  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account_v1.argocd_registration.metadata[0].name
    namespace = kubernetes_namespace_v1.platform_system.metadata[0].name
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
    "name"   = var.cluster_name
    "server" = "https://kubernetes.default.svc.cluster.local"
    "config" = jsonencode({
      "bearerToken" = kubernetes_secret_v1.argocd_registration_token.data.token
      "tlsClientConfig" = {
        "insecure" = false,
        "caData"   = base64encode(kubernetes_secret_v1.argocd_registration_token.data["ca.crt"])
      }
    })
  }
}
