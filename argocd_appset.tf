# Represents one Kubernetes resource by supplying a manifest attribute.
#
# https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/manifest
#
resource "kubernetes_manifest" "argocd_appset_platform" {
  manifest = {
    "apiVersion" = "argoproj.io/v1alpha1"
    "kind"       = "ApplicationSet"
    "metadata" = {
      "name"      = "aurora-platform"
      "namespace" = kubernetes_namespace_v1.platform_management_system.metadata[0].name
    }
    "spec" = {
      "generators" = [
        {
          "git" = {
            "files" = [
              {
                "path" = var.github_path
              }
            ]
            "repoURL"  = var.github_url
            "revision" = var.github_branch
          }
        }
      ]
      "syncPolicy" = {
        "preserveResourcesOnDeletion" = true
      }
      "template" = {
        "metadata" = {
          "name" = "platform-{{ path.basename }}"
        }
        "spec" = {
          "destination" = {
            "name"      = "in-cluster"
            "namespace" = kubernetes_namespace_v1.platform_management_system.metadata[0].name
          }
          "project" = "aurora"
          "source" = {
            ### Choose either remote helm repo or git based helm chart
            ### If using remote helm repo
            "chart"         = "aurora-platform"
            "repoURL"       = "https://gccloudone-aurora.github.io/aurora-platform-charts"
            ### End remote helm repo ###
            ### If using git based helm chart
            # "path"          = "stable/aurora-platform"
            # "repoURL"       = "https://github.com/gccloudone-aurora/aurora-platform-charts.git"
            ### End git based helm chart ###
            "helm" = {
              "releaseName" = "{{ path.basename }}"
              "values"      = <<EOT
{{ settings }}
EOT
            }
            
            "targetRevision" = "{{ version }}"
          }
          "syncPolicy" = {
            "automated" = {
              "prune"    = false
              "selfHeal" = true
            }
          }
        }
      }
    }
  }
}
