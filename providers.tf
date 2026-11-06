terraform {
  required_version = ">= 1.9.0, < 2.0.0"

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
  config_path    = var.config_path
  config_context = var.config_context
}

provider "helm" {
  kubernetes = {
    config_path    = var.config_path
    config_context = var.config_context
  }
}
