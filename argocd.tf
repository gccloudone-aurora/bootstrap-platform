# A Release is an instance of a helm chart.
#
# https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release
#
resource "helm_release" "argo_operator" {
  name            = "argo-operator"
  repository      = "https://gccloudone-aurora.github.io/aurora-platform-charts"
  chart           = "argocd-operator"
  namespace       = kubernetes_namespace_v1.argo_operator_system.metadata[0].name
  atomic          = true
  timeout         = 600
  upgrade_install = true
  max_history     = 2
  version         = var.argocd_chart_versions.operator

  values = [yamlencode({
    operator = {
      livenessProbe = {
        initialDelaySeconds = 180
        timeoutSeconds      = 5
        failureThreshold    = 6
      }
      readinessProbe = {
        timeoutSeconds = 5
      }
    }
  })]

  set = [
    {
      name  = "operator.nsToWatch"
      value = ""
    },
    {
      name  = "operator.nsClusterConfig"
      value = kubernetes_namespace_v1.platform_management_system.metadata[0].name
    }
  ]

  depends_on = [kubernetes_manifest.allow_egress_to_apiserver_from_platform]
}

locals {
  # Add new configurations as bootstrap is developed
  argocd_values = {
    openstack = {
      disableAdmin = false
      logLevel     = "info"
      controller = {
        resources = {
          requests = { cpu = "250m", memory = "512Mi" }
          limits   = { cpu = "1", memory = "1Gi" }
        }
      }
      repo = {
        resources = {
          requests = { cpu = "250m", memory = "256Mi" }
          limits   = { cpu = "1", memory = "1Gi" }
        }
      }
      server = {
        service = {
          type = "ClusterIP"
        }
        resources = {
          requests = { cpu = "100m", memory = "128Mi" }
          limits   = { cpu = "500m", memory = "256Mi" }
        }
      }
      redis = {
        resources = {
          requests = { cpu = "100m", memory = "128Mi" }
          limits   = { cpu = "500m", memory = "256Mi" }
        }
      }
      applicationSet = {
        resources = {
          requests = { cpu = "100m", memory = "128Mi" }
          limits   = { cpu = "500m", memory = "256Mi" }
        }
      }
      argocdVaultPlugin = {
        enabled = false
      }
    },
    azure = {
      repo = {
        labels = {
          "azure.workload.identity/use" = "true"
        },
        serviceAccountAnnotations = {
          "azure.workload.identity/client-id" = var.client_id
        }
      }
      argocdVaultPlugin = {
        env = {
          ARGOCD_ENV_AVP_TYPE        = "azurekeyvault"
          ARGOCD_ENV_AZURE_CLIENT_ID = var.client_id
        }
      }
    },
    gcp = {
      repo = {
        serviceAccountAnnotations = {
          "iam.gke.io/gcp-service-account" = "argocd-repo-server@${var.gcp_project_id}.iam.gserviceaccount.com" # If using GSA to KSA binding
        }
      }
      argocdVaultPlugin = {
        env = {
          ARGOCD_ENV_AVP_TYPE = "gcpsecretmanager"
        }
      }
    }
  }

  argocd_instance_base_values = merge(
    local.argocd_values[var.k8s_provider],
    {
      disableAdmin = var.sso.disable_admin
      metrics = {
        serviceMonitor = {
          enabled = var.argocd_service_monitor_enabled
        }
      }
      server = merge(try(local.argocd_values[var.k8s_provider].server, {}), {
        service = { type = var.argocd_server_service_type }
      })
    },
  )

  argocd_instance_values = merge(
    local.argocd_instance_base_values,
    {
      for component, resources in var.argocd_resources :
      component => merge(try(local.argocd_instance_base_values[component], {}), { resources = resources })
    },
    {
      adminSecurityGroup = var.sso.enabled ? var.sso.admin_group : ""
      oidcAuthSP = {
        tenantID     = var.sso.enabled ? var.sso.tenant_id : ""
        clientID     = var.sso.enabled ? var.sso.client_id : ""
        clientSecret = var.sso.enabled ? var.sso.client_secret : ""
      }
    },
  )
}

# A Release is an instance of a helm chart.
#
# https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release
#
resource "helm_release" "argocd_instance" {
  name            = "argocd-instance"
  repository      = "https://gccloudone-aurora.github.io/aurora-platform-charts"
  chart           = "argocd-instance"
  namespace       = kubernetes_namespace_v1.platform_management_system.metadata[0].name
  atomic          = true
  upgrade_install = true
  max_history     = 2
  force_update    = true
  version         = var.argocd_chart_versions.instance

  values = [
    yamlencode({
      argocdInstance = local.argocd_instance_values
    })
  ]

  depends_on = [helm_release.argo_operator]
}
