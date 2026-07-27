# Azure bootstrap example (standard)

Installs Argo CD via the parent module onto an AKS cluster created by
[`../prerequisites`](../prerequisites) (VNet + AKS, separate state).

For kubeconfig auth against an existing cluster, see
[`../kubeconfig`](../kubeconfig).

## Prerequisites

1. Apply [`../prerequisites`](../prerequisites) (VNet via
   [`terraform-azure-virtual-network`](https://github.com/gccloudone-aurora-iac/terraform-azure-virtual-network),
   AKS via native `azurerm`)
2. GitHub credentials for the platform clusters repository

## Apply

```bash
# 1. VNet + AKS
cd ../prerequisites
terraform init
terraform apply

# 2. Bootstrap Argo CD
cd ../standard
cp terraform.tfvars.example terraform.tfvars
# fill in platform and github_auth; optionally cluster_registration

terraform init
terraform apply -target=module.bootstrap.helm_release.argo_operator
terraform apply -target=module.bootstrap.helm_release.argocd_instance
terraform apply
```

`prerequisites_remote_state` defaults to `../prerequisites/terraform.tfstate`.
`azure_client_id` is read from the prerequisites UAMI output.

## Temporary Argo CD UI access

```bash
kubectl port-forward svc/argocd-server -n platform-management-system 8080:80
kubectl get secret argocd-cluster -n platform-management-system \
  -o go-template='{{index .data "admin.password" | base64decode}}'; echo
```

Then open https://localhost:8080 (user `admin`).
