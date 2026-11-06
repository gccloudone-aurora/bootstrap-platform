# Bootstrap

This Terraform configuration can run standalone or be called as a local module.
Keep its state while Terraform manages the bootstrap resources.

## Running Bootstrap

```sh
terraform init
terraform plan
terraform apply
```

The target cluster must already exist and be reachable. Terraform installs the
operator and instance, then a local Helm release waits for the Argo CD CRDs to be
created and established. A dependent release installs the four AppProjects and
the ApplicationSet from `charts/argocd-bootstrap`. No shell wrapper or targeted
applies are required. The readiness job uses the pinned `crd_wait_image` input;
override it for your approved registry or Kubernetes client version.

Existing deployments that already manage these resources through
`kubernetes_manifest` need an explicit state and Helm-ownership migration before
applying this refactor. Do not approve a plan that destroys existing projects or
the ApplicationSet. Fresh deployments do not need that migration.

Run chart regression checks with `ruby tests/chart_test.rb` and mocked Terraform
plan checks with `terraform test -filter=tests/bootstrap.tftest.hcl`.

## Deployment Safeguards

`argocd_service_monitor_enabled` defaults to false. Enable it only after Prometheus
Operator and the `servicemonitors.monitoring.coreos.com` CRD are installed. This
overrides chart versions that enable ServiceMonitor creation by default; it does
not install a monitoring stack.

Generated applications require manual sync by default. Set `application_auto_sync`
only after reviewing them; pruning remains disabled. `project_permissions`
restricts repositories to the configured Git and platform Helm repositories and
destinations to the local cluster. Cluster-resource permissions remain broad for
platform compatibility; explicitly narrow `cluster_resources` after reviewing the
resources your platform charts require.

Network policies retain the working checkpoint's DNS selectors, metadata
allowances, and outbound access. API-server egress permits TCP 443 and RKE2 TCP
6443, restricted to the `kube-apiserver` entity, and precedes operator installation.

`sso` prepares the pinned chart's Entra OIDC and admin-group configuration, disabled
by default. Local admin can be disabled only with enabled SSO and an explicit
`access_verified` acknowledgment. The chart does not support a read-only group
mapping or generic OIDC configuration; those require an upstream chart extension.
Do not assume supplying an unsupported value configures authorization.

`argocd_resources`, `argocd_server_service_type`, and `argocd_chart_versions` expose
supported chart controls. Defaults keep ClusterIP access and pinned versions.
Resource requests/limits need tuning against observed workloads. CI runs mocked
platform plans and chart checks without credentials.

Cluster registration uses native Kubernetes `_v1` resources. All current consumers
have migrated, so temporary imports and legacy removal blocks are no longer
needed. Older state backups must be reconciled with the current resource addresses
before applying; do not approve replacement or deletion of working registration
credentials merely to reconcile state.

## Temporary Access for ArgoCD
If argocd access is required and no ingress has been setup yet, you can port-forward the argocd service and access the UI locally.

```
# Port-Forward ArgoCD Service
kubectl port-forward svc/argocd-server -n platform-management-system 8080:80
# Get Temporay Admin Secret
kubectl get secret argocd-cluster -n platform-management-system -o go-template='{{index .data "admin.password" | base64decode}}'; echo
# Access ArgoCD locally in browser and login with username: admin password: [argocd admin secret]
https://localhost:8080
```

## Configuring AVP for specific platforms

Use the terraform variable `k8s_provider` and set it to the appropriate platform where Kubernetes is deployed. If adding new platforms update the variable validation accordingly and add the configuration to `local.argocd_values`.

### OpenStack

Set `k8s_provider = "openstack"`. This mode disables the vault plugin and does not
configure Azure/GCP workload identity. Configure a secrets backend before enabling
the plugin. Both providers use `config_path` (default `~/.kube/config`) and the
explicit `config_context`.

The Argo CD server uses `ClusterIP` access and `info` logging. Local admin access
remains enabled until SSO and group-to-role mappings are configured and tested.
Use port-forwarding or an explicitly configured ingress with TLS for access.
Controller, repo server, API server, Redis, and ApplicationSet resources have
initial CPU/memory requests and limits; tune these against observed usage and
the number and size of managed applications.

### Azure

Ensure `argocdInstance` value is set to:
```
argocdInstance = {
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
      ARGOCD_ENV_AVP_TYPE       = "azurekeyvault" # Use Azure keyvault, passed as
                                                  # environment variable to the sidecar
                                                  # when installed via Helm
      ARGOCD_ENV_AZURE_CLIENT_ID = var.client_id # Azure envrionment-based authentication
    }
  }
}
```

### GCP
When setting up to use GCP Secrets Manager, ensure the `argocd-repo-server` service account is assigned permissions in GCP via Workload Identity. This can be done by binding a GCP service account (GSA) to the `argocd-repo-server` Kubernetes service account (KSA) or directly using the KSA as a principal in GCP if `GKE_METADATA` is set as the workload metadata config mode.

```
argocdInstance = {
  repo = {
    serviceAccountAnnotations = {
      "iam.gke.io/gcp-service-account" = "argocd-repo-server@<YOUR_GCP_PROJECT_ID>.iam.gserviceaccount.com"     # If using GSA to KSA binding
    }
  }
  argocdVaultPlugin = {
    env = {
      ARGOCD_ENV_AVP_TYPE       = "gcpsecretmanager"  # Use GCP Secrets Manager, passed as
                                                      # environment variable to the sidecar
                                                      # when installed via Helm
    }
  }
}
```
