provider "kubernetes" {
  # Kubeconfig-based auth (default)
  config_path    = var.cluster_host == null ? var.kubeconfig_path : null
  config_context = var.cluster_host == null ? var.kubeconfig_context : null

  # Direct auth (for CI/CD or programmatic use)
  host                   = var.cluster_host
  cluster_ca_certificate = var.cluster_ca_certificate
  token                  = var.cluster_token
}

locals {
  # Resolve database/redis host based on whether we deploy them in-cluster
  effective_database_host = var.database_host != "" ? var.database_host : "postgres.${var.namespace}.svc.cluster.local"
  effective_redis_host    = var.redis_host != "" ? var.redis_host : "redis.${var.namespace}.svc.cluster.local"
  redis_url               = "redis://${local.effective_redis_host}:${var.redis_port}/0"
  redis_url_switch        = "redis://${local.effective_redis_host}:${var.redis_port}/1"

  # Internal service DNS names
  somleng_api_host   = "somleng-api.${var.namespace}.svc.cluster.local"
  switch_host        = "somleng-switch.${var.namespace}.svc.cluster.local"
  freeswitch_host    = "freeswitch.${var.namespace}.svc.cluster.local"
  rating_engine_host = "rating-engine.${var.namespace}.svc.cluster.local"
  anycable_rpc_host  = "anycable-rpc.${var.namespace}.svc.cluster.local"
}
