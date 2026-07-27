locals {
  cluster_name                       = data.terraform_remote_state.prerequisites.outputs.cluster_name
  cluster_endpoint                   = data.terraform_remote_state.prerequisites.outputs.cluster_endpoint
  cluster_certificate_authority_data = data.terraform_remote_state.prerequisites.outputs.cluster_certificate_authority_data
}
