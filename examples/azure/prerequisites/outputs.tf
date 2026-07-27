output "cluster_name" {
  description = "AKS cluster name"
  value       = azurerm_kubernetes_cluster.this.name
}

output "cluster_endpoint" {
  description = "AKS API endpoint"
  value       = azurerm_kubernetes_cluster.this.kube_config[0].host
  sensitive   = true
}

output "cluster_certificate_authority_data" {
  description = "Base64-encoded cluster CA"
  value       = azurerm_kubernetes_cluster.this.kube_config[0].cluster_ca_certificate
  sensitive   = true
}

output "client_certificate" {
  description = "Base64-encoded client certificate for kubeconfig auth"
  value       = azurerm_kubernetes_cluster.this.kube_config[0].client_certificate
  sensitive   = true
}

output "client_key" {
  description = "Base64-encoded client key for kubeconfig auth"
  value       = azurerm_kubernetes_cluster.this.kube_config[0].client_key
  sensitive   = true
}

output "azure_client_id" {
  description = "User-assigned managed identity client ID for Argo CD workload identity / AVP"
  value       = azurerm_user_assigned_identity.argocd.client_id
}

output "update_kubeconfig_command" {
  description = "Merge this cluster into the local kubeconfig"
  value       = "az aks get-credentials --resource-group ${azurerm_resource_group.this.name} --name ${azurerm_kubernetes_cluster.this.name}"
}
