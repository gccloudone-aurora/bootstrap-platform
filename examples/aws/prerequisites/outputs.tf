output "cluster_name" {
  description = "EKS cluster name"
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "EKS API endpoint"
  value       = module.eks.cluster_endpoint
}

output "cluster_certificate_authority_data" {
  description = "Base64-encoded cluster CA"
  value       = module.eks.cluster_certificate_authority_data
  sensitive   = true
}

output "update_kubeconfig_command" {
  description = "Merge this cluster into the local kubeconfig"
  value       = "aws eks update-kubeconfig --region ${data.aws_region.current.id} --name ${module.eks.cluster_name}"
}
