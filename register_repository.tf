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
    "url"  = var.platform_git_repository.url
  }

  depends_on = [helm_release.argocd_instance]
}

locals {
  github_app = try(var.github_auth.github_app, null)
  github_pat = try(var.github_auth.pat, null)

  repo_creds_url = local.github_app != null ? coalesce(local.github_app.creds_url, var.platform_git_repository.url) : var.platform_git_repository.url

  repo_creds_data = local.github_app != null ? merge(
    {
      type                    = "git"
      url                     = local.repo_creds_url
      githubAppID             = local.github_app.id
      githubAppInstallationID = local.github_app.installation_id
      githubAppPrivateKey     = local.github_app.private_key
    },
    local.github_app.enterprise_base_url != null ? {
      githubAppEnterpriseBaseUrl = local.github_app.enterprise_base_url
    } : {}
    ) : {
    type     = "git"
    url      = local.repo_creds_url
    username = local.github_pat.username
    password = local.github_pat.token
  }
}

resource "kubernetes_secret_v1" "project_aurora_mgmt_repo_creds" {
  metadata {
    name      = "project-aurora-mgmt-repo-creds"
    namespace = kubernetes_namespace_v1.platform_management_system.metadata[0].name
    labels = {
      "argocd.argoproj.io/secret-type" = "repo-creds"
    }
  }

  type = "Opaque"

  data = local.repo_creds_data

  depends_on = [helm_release.argocd_instance]
}
