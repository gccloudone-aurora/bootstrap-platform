# Prerequisites: VNet + AKS

Creates a resource group and AKS cluster with native `azurerm` resources, and
uses [`terraform-azure-virtual-network`](https://github.com/gccloudone-aurora-iac/terraform-azure-virtual-network)
`v2.0.1` for the VNet/subnets.

Own Terraform state (do not share with the [`../standard`](../standard) bootstrap apply).

Also creates a user-assigned managed identity whose client ID is passed to
bootstrap as `azure_client_id` (workload identity / AVP).

## Apply

```bash
# Authenticate: az login
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
