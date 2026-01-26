# Specify how groups of pods are allowed to communicate.
#
# https://registry.terraform.io/providers/hashicorp/kubernetes/1.13.3/docs/resources/network_policy
#
resource "kubernetes_network_policy" "allow_same_namespace" {
  metadata {
    name      = "allow-same-namespace"
    namespace = kubernetes_namespace_v1.platform_management_system.metadata[0].name
  }
  spec {
    pod_selector {}
    ingress {
      from {
        pod_selector {}
      }
    }
    egress {
      to {
        pod_selector {}
      }
    }
    policy_types = ["Ingress", "Egress"]
  }
}

# Specify how groups of pods are allowed to communicate.
#
# https://registry.terraform.io/providers/hashicorp/kubernetes/1.13.3/docs/resources/network_policy
#
resource "kubernetes_network_policy" "allow_all_outbound" {
  metadata {
    name      = "allow-all-outbound"
    namespace = kubernetes_namespace_v1.platform_management_system.metadata[0].name
  }
  spec {
    pod_selector {}
    egress {
      to {
        ip_block {
          cidr = "0.0.0.0/0"
        }
      }
    }
    policy_types = ["Egress"]
  }
}

# Represents one Kubernetes resource by supplying a manifest attribute.
#
# https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/manifest
#
# TODO: https://github.com/cilium/cilium/issues/20550#issuecomment-1840835096
#
resource "kubernetes_manifest" "cilium_network_policy" {
  manifest = {
    "apiVersion" = "cilium.io/v2"
    "kind"       = "CiliumNetworkPolicy"
    "metadata" = {
      "name"      = "allow-egress-apiserver"
      "namespace" = kubernetes_namespace_v1.platform_management_system.metadata[0].name
    }
    "spec" = {
      "egress" = [
        {
          "toEntities" = [
            "kube-apiserver"
          ]
        }
      ]
      "endpointSelector" = {}
    }
  }
}
