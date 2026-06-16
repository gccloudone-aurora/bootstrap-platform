# Bootstrap

This Terraform module should be treated as a root module. Run it once to stand
up your infrastructure, then delete the statefile.

## Running Bootstrap
Need specific order of operations to allow CRDs to exist.

```
# Apply the operator helm chart
terraform apply -target=helm_release.argo_operator
# Apply the argocd helm chart
terraform apply -target=helm_release.argocd_instance
# Apply everything else required.
terraform apply
```

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