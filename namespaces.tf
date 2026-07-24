# Multiple virtual clusters backed by the same physical cluster.
#
# https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/namespace_v1
#
resource "kubernetes_namespace_v1" "argo_operator_system" {
  metadata {
    name = "argo-operator-system"
    labels = {
      "namespace.ssc-spc.gc.ca/purpose" = "system"
    }
  }

  lifecycle {
    ignore_changes = [
      metadata[0].annotations["cattle.io/status"],
      metadata[0].annotations["lifecycle.cattle.io/create.namespace-auth"]
    ]
  }
}

# Multiple virtual clusters backed by the same physical cluster.
#
# https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/namespace_v1
#
# Only created when bootstrap manages argocd-mgmt itself. On AWS, the environment
# kubernetes-bootstrap module already owns platform-system.
resource "kubernetes_namespace_v1" "platform_system" {
  count = var.cluster_registration == null ? 1 : 0

  metadata {
    name = "platform-system"
    labels = {
      "namespace.ssc-spc.gc.ca/purpose" = "system"
    }
  }

  lifecycle {
    ignore_changes = [
      metadata[0].annotations["cattle.io/status"],
      metadata[0].annotations["lifecycle.cattle.io/create.namespace-auth"]
    ]
  }
}

# Multiple virtual clusters backed by the same physical cluster.
#
# https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/namespace_v1
#
resource "kubernetes_namespace_v1" "platform_management_system" {
  metadata {
    name = "platform-management-system"
    labels = {
      "namespace.ssc-spc.gc.ca/purpose" = "system"
    }
  }

  lifecycle {
    ignore_changes = [
      metadata[0].annotations["cattle.io/status"],
      metadata[0].annotations["lifecycle.cattle.io/create.namespace-auth"]
    ]
  }
}
