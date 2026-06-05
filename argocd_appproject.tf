# Represents one Kubernetes resource by supplying a manifest attribute.
#
# https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/manifest
#
resource "kubernetes_manifest" "argocd_appproject_aurora" {
  depends_on = [ helm_release.argocd_instance ]
  manifest = {
    "apiVersion" = "argoproj.io/v1alpha1"
    "kind"       = "AppProject"
    "metadata" = {
      "name"      = "aurora"
      "namespace" = kubernetes_namespace_v1.platform_management_system.metadata[0].name
    }
    "spec" = {
      "clusterResourceWhitelist" = [
        {
          "group" = "*"
          "kind"  = "*"
        }
      ]
      "description" = "App Project for Aurora"
      "destinations" = [
        {
          "namespace" = "*"
          "server"    = "*"
        }
      ]
      "orphanedResources" = {
        "warn" = true
      }
      "sourceRepos" = ["*"]
      "syncWindows" = [
        {
          "clusters"   = ["*"]
          "duration"   = "3h"
          "kind"       = "allow"
          "manualSync" = true
          "schedule"   = "* 19 * * 2,4"
          "timeZone"   = "America/Toronto"
        }
      ]
    }
  }
}

# Represents one Kubernetes resource by supplying a manifest attribute.
#
# https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/manifest
#
resource "kubernetes_manifest" "argocd_appproject_aurora_core" {
  depends_on = [ helm_release.argocd_instance ]
  manifest = {
    "apiVersion" = "argoproj.io/v1alpha1"
    "kind"       = "AppProject"
    "metadata" = {
      "name"      = "aurora-core"
      "namespace" = kubernetes_namespace_v1.platform_management_system.metadata[0].name
    }
    "spec" = {
      "clusterResourceWhitelist" = [
        {
          "group" = "*"
          "kind"  = "*"
        }
      ]
      "description" = "App Project for Aurora Core"
      "destinations" = [
        {
          "namespace" = "*"
          "server"    = "*"
        }
      ]
      "orphanedResources" = {
        "warn" = true
      }
      "sourceRepos" = ["*"]
      "syncWindows" = [
        {
          "clusters"   = ["*"]
          "duration"   = "3h"
          "kind"       = "allow"
          "manualSync" = true
          "schedule"   = "* 19 * * 2,4"
          "timeZone"   = "America/Toronto"
        }
      ]
    }
  }
}

# Represents one Kubernetes resource by supplying a manifest attribute.
#
# https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/manifest
#
resource "kubernetes_manifest" "argocd_appproject_aurora_app" {
  depends_on = [ helm_release.argocd_instance ]
  manifest = {
    "apiVersion" = "argoproj.io/v1alpha1"
    "kind"       = "AppProject"
    "metadata" = {
      "name"      = "aurora-app"
      "namespace" = kubernetes_namespace_v1.platform_management_system.metadata[0].name
    }
    "spec" = {
      "clusterResourceWhitelist" = [
        {
          "group" = "*"
          "kind"  = "*"
        }
      ]
      "description" = "App Project for Aurora App"
      "destinations" = [
        {
          "namespace" = "*"
          "server"    = "*"
        }
      ]
      "orphanedResources" = {
        "warn" = true
      }
      "sourceRepos" = ["*"]
      "syncWindows" = [
        {
          "clusters"   = ["*"]
          "duration"   = "3h"
          "kind"       = "allow"
          "manualSync" = true
          "schedule"   = "* 19 * * 2,4"
          "timeZone"   = "America/Toronto"
        }
      ]
    }
  }
}

# Represents one Kubernetes resource by supplying a manifest attribute.
#
# https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/manifest
#
resource "kubernetes_manifest" "argocd_appproject_aurora_solution" {
  manifest = {
    "apiVersion" = "argoproj.io/v1alpha1"
    "kind"       = "AppProject"
    "metadata" = {
      "name"      = "aurora-solution"
      "namespace" = kubernetes_namespace_v1.platform_management_system.metadata[0].name
    }
    "spec" = {
      "clusterResourceWhitelist" = [
        {
          "group" = "*"
          "kind"  = "*"
        }
      ]
      "description" = "App Project for Aurora Solution"
      "destinations" = [
        {
          "namespace" = "*"
          "server"    = "*"
        }
      ]
      "orphanedResources" = {
        "warn" = true
      }
      "sourceRepos" = ["*"]
      "syncWindows" = [
        {
          "clusters"   = ["*"]
          "duration"   = "3h"
          "kind"       = "allow"
          "manualSync" = true
          "schedule"   = "* 19 * * 2,4"
          "timeZone"   = "America/Toronto"
        }
      ]
    }
  }
}
