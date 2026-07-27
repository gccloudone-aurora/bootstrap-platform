output "cluster_name" {
  description = "GKE cluster name"
  value       = google_container_cluster.this.name
}

output "cluster_endpoint" {
  description = "GKE API endpoint (host only, no scheme)"
  value       = google_container_cluster.this.endpoint
  sensitive   = true
}

output "cluster_certificate_authority_data" {
  description = "Base64-encoded cluster CA"
  value       = google_container_cluster.this.master_auth[0].cluster_ca_certificate
  sensitive   = true
}

output "gcp_project_id" {
  description = "GCP project ID (for bootstrap gcp_project_id / Workload Identity annotation)"
  value       = var.project_id
}

output "argocd_repo_server_service_account_email" {
  description = "GSA email annotated onto the Argo CD repo-server KSA"
  value       = google_service_account.argocd_repo_server.email
}

output "update_kubeconfig_command" {
  description = "Merge this cluster into the local kubeconfig"
  value       = "gcloud container clusters get-credentials ${google_container_cluster.this.name} --region ${var.region} --project ${var.project_id}"
}
