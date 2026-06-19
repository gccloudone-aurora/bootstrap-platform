# Mechanism to inject containers with sensitive information.
#
# https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/secret
#
resource "kubernetes_secret_v1" "project_aurora_mgmt" {
  metadata {
    name      = "project-aurora-mgmt"
    namespace = kubernetes_namespace_v1.platform_management_system.metadata[0].name
    labels = {
      "argocd.argoproj.io/secret-type" = "repository"
    }
  }

  type = "Opaque"

  data = {
    "type" = "git"
    "url"  = var.github_url
  }
}

# Mechanism to inject containers with sensitive information.
#
# https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/secret
#
resource "kubernetes_secret_v1" "project_aurora_mgmt_repo_creds" {
  metadata {
    name      = "project-aurora-mgmt-repo-creds"
    namespace = kubernetes_namespace_v1.platform_management_system.metadata[0].name
    labels = {
      "argocd.argoproj.io/secret-type" = "repo-creds"
    }
  }

  type = "Opaque"

  data = {
    "type"     = "git"
    "url"      = var.github_url
    "password" = var.github_token
    "username" = var.github_username
  }
}
