# Bootstrap

This Terraform module should be treated as a root module. Run it once to stand
up your infrastructure, then delete the statefile.

## Configuring AVP for specific platforms

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