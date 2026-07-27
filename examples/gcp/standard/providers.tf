provider "google" {
  project = local.gcp_project_id
}

provider "kubernetes" {
  host                   = "https://${local.cluster.endpoint}"
  cluster_ca_certificate = base64decode(local.cluster.certificate_authority_data)
  token                  = data.google_client_config.default.access_token
}

provider "helm" {
  kubernetes = {
    host                   = "https://${local.cluster.endpoint}"
    cluster_ca_certificate = base64decode(local.cluster.certificate_authority_data)
    token                  = data.google_client_config.default.access_token
  }
}
