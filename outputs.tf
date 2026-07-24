output "argo_operator_namespace" {
  description = "Namespace where the Argo CD operator runs"
  value       = kubernetes_namespace_v1.argo_operator_system.metadata[0].name
}

output "platform_system_namespace" {
  description = "Namespace for platform system resources (e.g. argocd-mgmt service account)"
  value       = try(kubernetes_namespace_v1.platform_system[0].metadata[0].name, "platform-system")
}

output "platform_management_namespace" {
  description = "Namespace where the Argo CD instance, secrets, and AppSets run"
  value       = kubernetes_namespace_v1.platform_management_system.metadata[0].name
}

# Alias for callers that used the consolidated bootstrap-system layout.
output "bootstrap_namespace" {
  description = "Alias for platform_management_namespace"
  value       = kubernetes_namespace_v1.platform_management_system.metadata[0].name
}

output "argo_operator_release" {
  description = "Helm release name for the Argo CD operator"
  value       = helm_release.argo_operator.name
}

output "argocd_instance_release" {
  description = "Helm release name for the Argo CD instance"
  value       = helm_release.argocd_instance.name
}

output "port_forward_command" {
  description = "kubectl port-forward command for temporary Argo CD UI access"
  value       = "kubectl port-forward svc/argocd-server -n ${kubernetes_namespace_v1.platform_management_system.metadata[0].name} 8080:80"
}

output "admin_password_command" {
  description = "kubectl command to retrieve the temporary Argo CD admin password"
  value       = "kubectl get secret argocd-cluster -n ${kubernetes_namespace_v1.platform_management_system.metadata[0].name} -o go-template='{{index .data \"admin.password\" | base64decode}}'"
}

output "bootstrap_manifests_release" {
  description = "Helm release name for AppProjects, ApplicationSet, and Cilium policies"
  value       = helm_release.bootstrap_manifests.name
}
