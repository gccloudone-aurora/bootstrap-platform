provider "azurerm" {
  features {}
}

provider "kubernetes" {
  host                   = local.cluster.endpoint
  cluster_ca_certificate = base64decode(local.cluster.certificate_authority_data)
  client_certificate     = base64decode(local.cluster.client_certificate)
  client_key             = base64decode(local.cluster.client_key)
}

provider "helm" {
  kubernetes = {
    host                   = local.cluster.endpoint
    cluster_ca_certificate = base64decode(local.cluster.certificate_authority_data)
    client_certificate     = base64decode(local.cluster.client_certificate)
    client_key             = base64decode(local.cluster.client_key)
  }
}
