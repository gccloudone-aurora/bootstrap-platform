# Specify how groups of pods are allowed to communicate.
#
# https://registry.terraform.io/providers/hashicorp/kubernetes/1.13.3/docs/resources/network_policy
#
# resource "kubernetes_network_policy_v1" "allow_same_namespace" {
#   metadata {
#     name      = "allow-same-namespace"
#     namespace = kubernetes_namespace_v1.platform_management_system.metadata[0].name
#   }
#   spec {
#     pod_selector {}
#     ingress {
#       from {
#         pod_selector {}
#       }
#     }
#     egress {
#       to {
#         pod_selector {}
#       }
#     }
#     policy_types = ["Ingress", "Egress"]
#   }
# }

# Specify how groups of pods are allowed to communicate.
#
# https://registry.terraform.io/providers/hashicorp/kubernetes/1.13.3/docs/resources/network_policy
#
# resource "kubernetes_network_policy_v1" "allow_all_outbound" {
#   metadata {
#     name      = "allow-all-outbound"
#     namespace = kubernetes_namespace_v1.platform_management_system.metadata[0].name
#   }
#   spec {
#     pod_selector {}
#     egress {
#       to {
#         ip_block {
#           cidr = "0.0.0.0/0"
#         }
#       }
#     }
#     policy_types = ["Egress"]
#   }
# }

# Represents one Kubernetes resource by supplying a manifest attribute.
#
# https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/manifest
#
# TODO: https://github.com/cilium/cilium/issues/20550#issuecomment-1840835096
#
# resource "kubernetes_manifest" "allow_egress_apiserver_platform" {
#   manifest = {
#     "apiVersion" = "cilium.io/v2"
#     "kind"       = "CiliumNetworkPolicy"
#     "metadata" = {
#       "name"      = "allow-egress-apiserver"
#       "namespace" = kubernetes_namespace_v1.platform_management_system.metadata[0].name
#     }
#     "spec" = {
#       "egress" = [
#         {
#           "toEntities" = [
#             "kube-apiserver"
#           ]
#         }
#       ]
#       "endpointSelector" = {}
#     }
#   }
# }

# Represents one Kubernetes resource by supplying a manifest attribute.
#
# https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/manifest
#
# TODO: https://github.com/cilium/cilium/issues/20550#issuecomment-1840835096
#
# resource "kubernetes_manifest" "allow_egress_apiserver_argo" {
#   manifest = {
#     "apiVersion" = "cilium.io/v2"
#     "kind"       = "CiliumNetworkPolicy"
#     "metadata" = {
#       "name"      = "allow-egress-apiserver"
#       "namespace" = kubernetes_namespace_v1.argo_operator_system.metadata[0].name
#     }
#     "spec" = {
#       "egress" = [
#         {
#           "toEntities" = [
#             "kube-apiserver"
#           ]
#         }
#       ]
#       "endpointSelector" = {}
#     }
#   }
# }

### GKE Specific

# resource "kubernetes_network_policy_v1" "allow_egress_apiserver_platform" {
#   metadata {
#     name      = "allow-egress-apiserver"
#     namespace = kubernetes_namespace_v1.platform_management_system.metadata[0].name
#   }
#   spec {
#     pod_selector {}
#     egress {
#       ports {
#         port = "443"
#         protocol = "TCP"
#       }
#       to {
#         ip_block {
#           cidr = var.gke_control_plane_ip
#         }
#       }
#     }
#     policy_types = ["Egress"]
#   }
# }

# resource "kubernetes_network_policy_v1" "allow_egress_apiserver_argo" {
#   metadata {
#     name      = "allow-egress-apiserver"
#     namespace = kubernetes_namespace_v1.argo_operator_system.metadata[0].name
#   }
#   spec {
#     pod_selector {}
#     egress {
#       ports {
#         port = "443"
#         protocol = "TCP"
#       }
#       to {
#         ip_block {
#           cidr = var.gke_control_plane_ip
#         }
#       }
#     }
#     policy_types = ["Egress"]
#   }
# }

# resource "kubernetes_network_policy_v1" "allow_dns_egress_argo" {
#   metadata {
#     name = "allow-dns-egress"
#     namespace = kubernetes_namespace_v1.argo_operator_system.metadata[0].name
#   }

#   spec {
#     pod_selector {}
#     policy_types = ["Egress"]

#     egress {
#       to {
#         namespace_selector {
#           match_labels = {
#             "kubernetes.io/metadata.name" = "kube-system"
#           }
#         }
#         pod_selector {
#           match_labels = {
#             "k8s-app" = "kube-dns"
#           }
#         }
#       }
#       ports {
#         port = "53"
#         protocol = "UDP"
#       }
#       ports {
#         port = "53"
#         protocol = "TCP"
#       }
#     }
#   }
# }

# resource "kubernetes_network_policy_v1" "allow_dns_egress_platform" {
#   metadata {
#     name = "allow-dns-egress"
#     namespace = kubernetes_namespace_v1.platform_management_system.metadata[0].name
#   }

#   spec {
#     pod_selector {}
#     policy_types = ["Egress"]

#     egress {
#       to {
#         namespace_selector {
#           match_labels = {
#             "kubernetes.io/metadata.name" = "kube-system"
#           }
#         }
#         pod_selector {
#           match_labels = {
#             "k8s-app" = "kube-dns"
#           }
#         }
#       }
#       ports {
#         port = "53"
#         protocol = "UDP"
#       }
#       ports {
#         port = "53"
#         protocol = "TCP"
#       }
#     }
#   }
# }

# resource "kubernetes_manifest" "cluster_wide_dns_egress" {
#   manifest = {
#     "apiVersion" = "cilium.io/v2"
#     "kind"       = "CiliumClusterwideNetworkPolicy"
#     "metadata" = {
#       "name"      = "global-allow-dns-egress"
#     }
#     "spec" = {
#       "description" = "Globally allow DNS egress to kube-system/kube-dns"
#       "egress" = [
#         {
#           "toEndpoints" = [
#             {
#               matchLabels = {
#                 "k8s:io.kubernetes.pod.namespace" = "kube-system"
#                 "k8s-app" = "kube-dns"
#               }
#             }
#           ]
#           "toPorts" = [
#             {
#               ports = [
#                 {
#                   port = "53"
#                   protocol = "UDP"
#                 },
#                 {
#                   port = "53"
#                   protocol = "TCP"
#                 }
#               ]
#             }
#           ]
#         }
#       ]
#       "endpointSelector" = {}
#     }
#   }
# }

# resource "kubernetes_manifest" "ccnp_allow_gke_metadata" {
#   manifest = {
#     "apiVersion" = "cilium.io/v2"
#     "kind"       = "CiliumClusterwideNetworkPolicy"
#     "metadata" = {
#       "name"      = "global-allow-metadata-egress"
#     }
#     "spec" = {
#       "egress" = [
#         {
#           "toCidr" = [
#             "169.254.169.254/32" # GKE Metadata Server
#           ]
#           "toPorts" = [
#             {
#               port = "80"
#               protocol = "TCP"
#             },
#             {
#               port = "8080"
#               protocol = "TCP"
#             }
#           ]
#         }
#       ]
#       "endpointSelector" = {}
#     }
#   }
# }