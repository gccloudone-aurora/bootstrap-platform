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

This Terraform module should be treated as a root module. Run it once to stand
up your infrastructure, then delete the statefile.

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
