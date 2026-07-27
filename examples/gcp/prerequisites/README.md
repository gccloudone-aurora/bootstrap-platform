# Prerequisites: VPC + GKE

Creates a VPC, subnet, and GKE cluster used by the [`../standard`](../standard)
GCP bootstrap example. Own Terraform state.

Also creates an `argocd-repo-server` GSA for Workload Identity / Secret Manager
(bind it to the Argo CD repo-server KSA after bootstrap if needed).

## Apply

```bash
# Authenticate: gcloud auth application-default login
cp terraform.tfvars.example terraform.tfvars
# set project_id

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
