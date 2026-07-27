# GCP bootstrap example (kubeconfig)

Installs Argo CD via the parent module using kubeconfig auth (`k8s_provider = "gcp"`).
Does not read cluster details from Terraform state.

For a self-contained VPC + GKE flow that wires providers from remote state, see
[`../standard`](../standard).

## Prerequisites

- GKE cluster reachable via kubeconfig (e.g. after `gcloud container clusters get-credentials`)
- `gcp_project_id` for the Workload Identity GSA annotation
- GitHub credentials for the platform clusters repository

## Apply

```bash
cp terraform.tfvars.example terraform.tfvars
# set config_context, gcp_project_id, platform, and github_auth

terraform init
terraform apply -target=module.bootstrap.helm_release.argo_operator
terraform apply -target=module.bootstrap.helm_release.argocd_instance
terraform apply
```

## Temporary Argo CD UI access

```bash
kubectl port-forward svc/argocd-server -n platform-management-system 8080:80
kubectl get secret argocd-cluster -n platform-management-system \
  -o go-template='{{index .data "admin.password" | base64decode}}'; echo
```

Then open https://localhost:8080 (user `admin`).
