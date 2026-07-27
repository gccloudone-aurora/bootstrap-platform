locals {
  env = data.terraform_remote_state.prerequisites.outputs

  ########################
  ## Cluster connection ##
  ########################

  cluster = {
    name                       = local.env.cluster_name
    endpoint                   = local.env.cluster_endpoint
    certificate_authority_data = local.env.cluster_certificate_authority_data
    client_certificate         = local.env.client_certificate
    client_key                 = local.env.client_key
  }

  ####################
  ## Azure identity ##
  ####################

  azure_client_id = local.env.azure_client_id
}
