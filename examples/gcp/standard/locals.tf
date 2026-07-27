locals {
  env = data.terraform_remote_state.prerequisites.outputs

  #########################
  ## Cluster connection  ##
  #########################

  cluster = {
    name                       = local.env.cluster_name
    endpoint                   = local.env.cluster_endpoint
    certificate_authority_data = local.env.cluster_certificate_authority_data
  }

  #########################
  ## GCP identity        ##
  #########################

  gcp_project_id = local.env.gcp_project_id
}
