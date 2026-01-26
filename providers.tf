terraform {
  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = "3.1.1"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "3.0.1"
    }
  }
}

provider "kubernetes" {
  config_path    = "~/.kube/config"
  config_context = "aurora-mgmt"
}

provider "helm" {
  kubernetes = {
    config_path    = "~/.kube/config"
    config_context = "aurora-mgmt"
  }
}
