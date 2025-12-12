resource "kubernetes_namespace_v1" "argo_operator_system" {
  metadata {
    name = "argo-operator-system"
    labels = {
      "namespace.ssc-spc.gc.ca/purpose" = "platform"
    }
  }

  lifecycle {
    ignore_changes = [
      metadata[0].annotations["cattle.io/status"],
      metadata[0].annotations["lifecycle.cattle.io/create.namespace-auth"]
    ]
  }
}

resource "kubernetes_namespace_v1" "platform_system" {
  metadata {
    name = "platform-system"
    labels = {
      "namespace.ssc-spc.gc.ca/purpose" = "platform"
    }
  }

  lifecycle {
    ignore_changes = [
      metadata[0].annotations["cattle.io/status"],
      metadata[0].annotations["lifecycle.cattle.io/create.namespace-auth"]
    ]
  }
}

resource "kubernetes_namespace_v1" "platform_management_system" {
  metadata {
    name = "platform-management-system"
    labels = {
      "namespace.ssc-spc.gc.ca/purpose" = "platform"
    }
  }

  lifecycle {
    ignore_changes = [
      metadata[0].annotations["cattle.io/status"],
      metadata[0].annotations["lifecycle.cattle.io/create.namespace-auth"]
    ]
  }
}
