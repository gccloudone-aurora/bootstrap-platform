# AWS bootstrap example (standard)

Installs Argo CD via the parent module onto an EKS cluster created by
[`../prerequisites`](../prerequisites) (VPC + EKS, separate state).

For kubeconfig auth against an existing cluster, see
[`../kubeconfig`](../kubeconfig).

For a fuller environment stack, prefer
[`terraform-aurora-aws-environment/examples/comprehensive/bootstrap`](../../../../terraform-aurora-aws-environment/examples/comprehensive/bootstrap).

## Prerequisites

1. Apply [`../prerequisites`](../prerequisites) (VPC + EKS)
2. GitHub credentials for the platform clusters repository

## Apply

```bash
# 1. VPC + EKS
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

## Temporary Argo CD UI access

```bash
kubectl port-forward svc/argocd-server -n platform-management-system 8080:80
kubectl get secret argocd-cluster -n platform-management-system \
  -o go-template='{{index .data "admin.password" | base64decode}}'; echo
```

Then open https://localhost:8080 (user `admin`).
