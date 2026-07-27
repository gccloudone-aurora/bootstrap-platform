provider "aws" {
  region = var.aws_region
}

provider "kubernetes" {
  host                   = local.cluster_endpoint
  cluster_ca_certificate = base64decode(local.cluster_certificate_authority_data)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    args        = ["eks", "get-token", "--cluster-name", local.cluster_name, "--region", var.aws_region]
    command     = "aws"
  }
}

provider "helm" {
  kubernetes = {
    host                   = local.cluster_endpoint
    cluster_ca_certificate = base64decode(local.cluster_certificate_authority_data)

    exec = {
      api_version = "client.authentication.k8s.io/v1beta1"
      args        = ["eks", "get-token", "--cluster-name", local.cluster_name, "--region", var.aws_region]
      command     = "aws"
    }
  }
}
