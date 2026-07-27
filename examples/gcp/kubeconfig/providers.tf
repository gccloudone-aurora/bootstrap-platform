provider "kubernetes" {
  config_path    = var.kubeconfig_path
  config_context = var.config_context
}

provider "helm" {
  kubernetes = {
    config_path    = var.kubeconfig_path
    config_context = var.config_context
  }
}
