mock_provider "kubernetes" {}
mock_provider "helm" {}

override_resource {
  target = kubernetes_secret_v1.argocd_registration_token
  values = {
    data = {
      token    = "test-token"
      "ca.crt" = "test-ca"
    }
  }
}

variables {
  k8s_provider    = "openstack"
  cluster_name    = "test-cluster"
  config_context  = "test-context"
  github_username = "test-user"
  github_token    = "test-token"
  github_url      = "https://github.com/example/platform.git"
  github_branch   = "main"
  github_path     = "platform/clusters/**/config.yaml"
}

run "plan_without_argocd_crds" {
  command = plan

  assert {
    condition     = yamldecode(helm_release.argocd_instance.values[0]).argocdInstance.metrics.serviceMonitor.enabled == false
    error_message = "ServiceMonitor creation must default off when monitoring CRDs are not guaranteed."
  }

  assert {
    condition     = length(kubernetes_manifest.csp_egress_to_metadata.manifest.spec.egress) == 2
    error_message = "The checkpoint metadata policy must remain unchanged on OpenStack."
  }

  assert {
    condition = (
      yamldecode(helm_release.argocd_bootstrap.values[0]).automation.enabled == false &&
      !contains(yamldecode(helm_release.argocd_bootstrap.values[0]).permissions.sourceRepos, "*") &&
      alltrue([for destination in yamldecode(helm_release.argocd_bootstrap.values[0]).permissions.destinations : destination.server != "*"])
    )
    error_message = "Defaults must restrict repository/cluster scope and automatic deployment."
  }

  assert {
    condition = (
      contains(yamldecode(file("${path.module}/manifests/allow-egress-to-apiserver-from-platform.yaml")).spec.egress[0].toEntities, "kube-apiserver") &&
      alltrue([
        for port in ["443", "6443"] :
        contains([
          for rule in yamldecode(file("${path.module}/manifests/allow-egress-to-apiserver-from-platform.yaml")).spec.egress[0].toPorts[0].ports :
          rule.port if rule.protocol == "TCP"
        ], port)
      ])
    )
    error_message = "API egress must allow both managed-cloud 443 and RKE2 6443, restricted to the kube-apiserver entity."
  }

  assert {
    condition = (
      yamldecode(helm_release.argo_operator.values[0]).operator.livenessProbe.initialDelaySeconds == 180 &&
      yamldecode(helm_release.argo_operator.values[0]).operator.livenessProbe.failureThreshold == 6 &&
      helm_release.argo_operator.timeout == 600
    )
    error_message = "The operator must have sufficient startup grace before liveness restarts it."
  }

  assert {
    condition = (
      helm_release.argocd_crds.chart == local.bootstrap_chart &&
      yamldecode(helm_release.argocd_crds.values[0]).phase == "readiness" &&
      yamldecode(helm_release.argocd_bootstrap.values[0]).phase == "resources"
    )
    error_message = "Bootstrap must use separate local Helm phases for readiness and custom resources."
  }

  assert {
    condition = yamldecode(helm_release.argocd_bootstrap.values[0]).git == {
      url    = var.github_url
      branch = var.github_branch
      path   = var.github_path
    }
    error_message = "Repository configuration must reach the bootstrap chart unchanged."
  }

  assert {
    condition     = yamldecode(helm_release.argocd_instance.values[0]).argocdInstance.argocdVaultPlugin.enabled == false
    error_message = "OpenStack must not enable an unconfigured vault plugin."
  }

  assert {
    condition = (
      yamldecode(helm_release.argocd_instance.values[0]).argocdInstance.server.service.type == "ClusterIP" &&
      yamldecode(helm_release.argocd_instance.values[0]).argocdInstance.disableAdmin == false &&
      yamldecode(helm_release.argocd_instance.values[0]).argocdInstance.logLevel == "info"
    )
    error_message = "OpenStack must use internal service access and retain admin access until SSO is configured."
  }

  assert {
    condition = alltrue([
      for component in ["controller", "repo", "server", "redis", "applicationSet"] :
      alltrue([
        for budget in ["requests", "limits"] :
        length(yamldecode(helm_release.argocd_instance.values[0]).argocdInstance[component].resources[budget].cpu) > 0 &&
        length(yamldecode(helm_release.argocd_instance.values[0]).argocdInstance[component].resources[budget].memory) > 0
      ])
    ])
    error_message = "All OpenStack Argo CD components must define CPU and memory requests and limits."
  }
}

run "azure_network_policies" {
  command = plan
  variables {
    k8s_provider = "azure"
    client_id    = "test-azure-client"
  }
  assert {
    condition = (
      length(kubernetes_manifest.csp_egress_to_metadata.manifest.spec.egress) == 2
      && yamldecode(helm_release.argocd_instance.values[0]).argocdInstance.repo.serviceAccountAnnotations["azure.workload.identity/client-id"] == "test-azure-client"
    )
    error_message = "Azure must retain the checkpoint metadata policy and workload identity settings."
  }
}

run "gcp_network_policies" {
  command = plan
  variables {
    k8s_provider   = "gcp"
    gcp_project_id = "test-gcp-project"
  }
  assert {
    condition = (
      length(kubernetes_manifest.csp_egress_to_metadata.manifest.spec.egress) == 2 &&
      yamldecode(helm_release.argocd_instance.values[0]).argocdInstance.repo.serviceAccountAnnotations["iam.gke.io/gcp-service-account"] == "argocd-repo-server@test-gcp-project.iam.gserviceaccount.com"
    )
    error_message = "GCP must retain its workload-identity metadata endpoints."
  }
}

run "prepare_entra_sso" {
  command = plan
  variables {
    sso = {
      enabled       = true
      tenant_id     = "test-tenant"
      client_id     = "test-client"
      client_secret = "test-secret"
      admin_group   = "test-admin-group"
    }
  }
  assert {
    condition = (
      yamldecode(helm_release.argocd_instance.values[0]).argocdInstance.oidcAuthSP.tenantID == "test-tenant" &&
      yamldecode(helm_release.argocd_instance.values[0]).argocdInstance.adminSecurityGroup == "test-admin-group" &&
      yamldecode(helm_release.argocd_instance.values[0]).argocdInstance.disableAdmin == false
    )
    error_message = "SSO settings must reach the chart without disabling the fallback admin."
  }
}

run "reject_premature_admin_disable" {
  command = plan
  variables {
    sso = { disable_admin = true }
  }
  expect_failures = [var.sso]
}

run "reject_incomplete_sso" {
  command = plan
  variables {
    sso = { enabled = true }
  }
  expect_failures = [var.sso]
}

run "monitoring_opt_in" {
  command = plan
  variables {
    argocd_service_monitor_enabled = true
  }
  assert {
    condition     = yamldecode(helm_release.argocd_instance.values[0]).argocdInstance.metrics.serviceMonitor.enabled == true
    error_message = "Explicit monitoring opt-in must reach the instance chart."
  }
}

run "resource_overrides" {
  command = plan
  variables {
    argocd_server_service_type = "NodePort"
    argocd_resources = {
      server = {
        requests = { cpu = "200m", memory = "256Mi" }
        limits   = { cpu = "1", memory = "512Mi" }
      }
    }
  }
  assert {
    condition = (
      yamldecode(helm_release.argocd_instance.values[0]).argocdInstance.server.service.type == "NodePort" &&
      yamldecode(helm_release.argocd_instance.values[0]).argocdInstance.server.resources.requests.cpu == "200m"
    )
    error_message = "Resource overrides must preserve server exposure settings."
  }
}