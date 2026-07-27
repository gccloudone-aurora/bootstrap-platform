# Prerequisites: VPC + EKS

Creates a VPC and EKS cluster used by the [`../standard`](../standard) AWS
bootstrap example. Own Terraform state (do not share with the bootstrap apply).

## Apply

```bash
terraform init
terraform apply
```

Then from `../standard`:

```bash
cp terraform.tfvars.example terraform.tfvars
# fill in platform and github_auth
terraform init
terraform apply -target=module.bootstrap.helm_release.argo_operator
terraform apply -target=module.bootstrap.helm_release.argocd_instance
terraform apply
```
