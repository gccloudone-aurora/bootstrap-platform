# Bootstrap

Terraform module that installs Argo CD (operator + instance), configures the
platform Git repository, and creates AppProjects / ApplicationSets for the
Aurora platform. Applications target `in-cluster`, or a registered cluster
name when `cluster_registration` is set.

Configure the `kubernetes` and `helm` providers in the **calling** root module
(for example EKS exec auth). This module does not declare provider blocks so it
can be composed into other stacks.

Kubeconfig-based and remote-state examples for each cloud:

| Provider | From prerequisites state | Kubeconfig |
|----------|--------------------------|------------|
| AWS | [`examples/aws/standard`](examples/aws/standard) | [`examples/aws/kubeconfig`](examples/aws/kubeconfig) |
| Azure | [`examples/azure/standard`](examples/azure/standard) | [`examples/azure/kubeconfig`](examples/azure/kubeconfig) |
| GCP | [`examples/gcp/standard`](examples/gcp/standard) | [`examples/gcp/kubeconfig`](examples/gcp/kubeconfig) |

On AWS, prefer a **separate state** root that reads
`terraform-aurora-aws-environment` outputs via `terraform_remote_state` and then
calls this module — see
[`../terraform-aurora-aws-environment/examples/comprehensive/bootstrap`](../terraform-aurora-aws-environment/examples/comprehensive/bootstrap).

## Usage (AWS / remote state root)

```hcl
data "terraform_remote_state" "environment" {
  backend = "s3" # or "local"
  config  = { /* ... */ }
}

module "argocd_bootstrap" {
  source = "../bootstrap-terraform"

  k8s_provider = "aws"

  platform = {
    git = {
      url    = "https://github.com/org/aurora-platform-clusters.git"
      branch = "main"
      path   = "clusters/non-prod/**/config.yaml"
    }
  }

  github_auth = {
    pat = {
      username = "aurora-svc"
      token    = var.github_token
    }
  }

  # Optional: register.clusters map (cluster name → server/token/caData).
  # cluster_registration = {
  #   (data.terraform_remote_state.environment.outputs.cluster_name) = {
  #     server = "https://kubernetes.default.svc.cluster.local"
  #     token  = data.terraform_remote_state.environment.outputs.argocd_service_account_token
  #     caData = base64encode(data.terraform_remote_state.environment.outputs.argocd_service_account_ca_cert)
  #   }
  # }
}
```

Required remote-state outputs (same names as `terraform-aurora-aws-environment`):

| Output | Purpose |
|--------|---------|
| `cluster_name` | EKS cluster name for provider auth (`eks get-token`); also register.clusters map key when set |
| `cluster_endpoint` | Kubernetes API endpoint for providers |
| `cluster_certificate_authority_data` | Cluster CA for providers |
| `argocd_service_account_token` | Optional; `cluster_registration[*].token` when registering clusters |
| `argocd_service_account_ca_cert` | Optional; base64-encode into `cluster_registration[*].caData` |

Namespaces:

| Namespace | Purpose |
|-----------|---------|
| `argo-operator-system` | Argo CD operator |
| `platform-management-system` | Argo CD instance, secrets, AppProjects, ApplicationSet |

Applications target Argo CD's built-in `in-cluster` destination when
`cluster_registration` is empty. When set (exactly one entry), the map key
is used as `destination.name` and the credentials are passed through as
`register.clusters`.

Repository and repo-creds secrets are created by the `argocd-instance`
Helm chart via its `register` values (not separate Terraform secret resources).
GitHub App auth for repo-creds requires chart version `>= 0.18.0`.

### Auto sync

Set `enable_auto_sync = false` to require manual syncs (ApplicationSet omits
`syncPolicy.automated`; AppProjects get a deny-all sync window with
`manualSync: true`). Default is `true` (automated sync always allowed; no
restrictive sync windows). Individual AppProjects can override with an
`autoSync` field in chart values if you customize `appProjects`.

## Temporary Access for ArgoCD

If Argo CD access is required and no ingress has been set up yet:

```
# Port-Forward ArgoCD Service
kubectl port-forward svc/argocd-server -n platform-management-system 8080:80
# Get Temporary Admin Secret
kubectl get secret argocd-cluster -n platform-management-system -o go-template='{{index .data "admin.password" | base64decode}}'; echo
# Access ArgoCD locally: https://localhost:8080  (user: admin)
```

AppProjects, ApplicationSet, and Cilium policies are installed with a local Helm
chart (`charts/bootstrap-aurora-platform`) after the Argo CD instance. This avoids
`kubernetes_manifest`, which requires CRD OpenAPI schemas at plan time.

## Configuring AVP for specific platforms

Use the terraform variable `k8s_provider` and set it to the appropriate platform
where Kubernetes is deployed.

### AWS

Set `k8s_provider = "aws"`. Grant the Argo CD service account access via EKS Pod
Identity (or IRSA) in the calling stack — for example the
`terraform-aurora-aws-environment` platform-components Argo CD module associates
`argocd-sa` in `platform-management-system`. The module configures:

```
argocdInstance = {
  argocdVaultPlugin = {
    env = {
      ARGOCD_ENV_AVP_TYPE = "awssecretsmanager"
    }
  }
}
```

### Azure

Set `k8s_provider = "azure"` and `azure_client_id` to the Entra app / managed
identity client ID. The module configures:

```
argocdInstance = {
  repo = {
    labels = {
      "azure.workload.identity/use" = "true"
    },
    serviceAccountAnnotations = {
      "azure.workload.identity/client-id" = var.azure_client_id
    }
  }
  argocdVaultPlugin = {
    env = {
      ARGOCD_ENV_AVP_TYPE        = "azurekeyvault"
      ARGOCD_ENV_AZURE_CLIENT_ID = var.azure_client_id
    }
  }
}
```

### GCP

Set `k8s_provider = "gcp"` and `gcp_project_id` to the project that owns the
Workload Identity GSA. The module annotates repo-server as
`argocd-repo-server@<gcp_project_id>.iam.gserviceaccount.com`. Ensure that GSA
has Secret Manager access via Workload Identity.

```
argocdInstance = {
  repo = {
    serviceAccountAnnotations = {
      "iam.gke.io/gcp-service-account" = "argocd-repo-server@<gcp_project_id>.iam.gserviceaccount.com"
    }
  }
  argocdVaultPlugin = {
    env = {
      ARGOCD_ENV_AVP_TYPE = "gcpsecretmanager"
    }
  }
}
```
