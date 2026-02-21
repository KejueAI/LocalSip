output "namespace" {
  description = "Kubernetes namespace where all resources are deployed"
  value       = kubernetes_namespace_v1.somleng.metadata[0].name
}

output "api_service" {
  description = "Somleng API service name and port"
  value       = "${kubernetes_service_v1.somleng_api.metadata[0].name}:3000"
}

output "api_domain" {
  description = "Domain configured for Somleng API ingress"
  value       = var.api_domain
}

output "ws_domain" {
  description = "Domain configured for AnyCable WebSocket ingress"
  value       = var.ws_domain
}

output "database_host" {
  description = "Effective database hostname"
  value       = local.effective_database_host
}

output "redis_url" {
  description = "Effective Redis URL"
  value       = local.redis_url
}
