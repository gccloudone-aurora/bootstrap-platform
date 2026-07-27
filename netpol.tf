# Specify how groups of pods are allowed to communicate.
#
# https://registry.terraform.io/providers/hashicorp/kubernetes/1.13.3/docs/resources/network_policy
#
resource "kubernetes_network_policy_v1" "allow_same_namespace" {
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
resource "kubernetes_network_policy_v1" "allow_all_outbound" {
  metadata {
    name      = "allow-egress-to-internet-from-argo"
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

### CCNP ###

# Policy to allow cluster-wide egress to kube-apiserver
resource "kubernetes_manifest" "allow_egress_to_apiserver_from_platform" {
  manifest = yamldecode(file("${path.module}/manifests/allow-egress-to-apiserver-from-platform.yaml"))
}

# Policy to allow egress to coredns and local dns cache
resource "kubernetes_manifest" "gcp_egress_to_coredns" {
  manifest = yamldecode(file("${path.module}/manifests/allow-egress-to-coredns.yaml"))
}

# Policy to allow egress to gke metadata and workload identity
# Layer 7 (dns-based filtering) network policies do not work in GCP
# https://docs.cloud.google.com/kubernetes-engine/docs/how-to/configure-cilium-network-policy
resource "kubernetes_manifest" "csp_egress_to_metadata" {
  manifest = yamldecode(file("${path.module}/manifests/allow-egress-to-metadata.yaml"))
}
