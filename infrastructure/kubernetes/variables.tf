# =============================================================================
# Cluster Authentication
# =============================================================================

variable "kubeconfig_path" {
  description = "Path to kubeconfig file"
  type        = string
  default     = "~/.kube/config"
}

variable "kubeconfig_context" {
  description = "Kubeconfig context to use (null = current context)"
  type        = string
  default     = null
}

variable "cluster_host" {
  description = "Kubernetes API server URL (alternative to kubeconfig, for CI/CD)"
  type        = string
  default     = null
}

variable "cluster_ca_certificate" {
  description = "PEM-encoded CA cert for the cluster (alternative to kubeconfig)"
  type        = string
  default     = null
  sensitive   = true
}

variable "cluster_token" {
  description = "Bearer token for cluster auth (alternative to kubeconfig)"
  type        = string
  default     = null
  sensitive   = true
}

# =============================================================================
# Namespace
# =============================================================================

variable "namespace" {
  description = "Kubernetes namespace for all resources"
  type        = string
  default     = "somleng"
}

# =============================================================================
# Container Images
# =============================================================================

variable "somleng_image" {
  description = "Docker image for Somleng API, Scheduler, AnyCable RPC"
  type        = string
  default     = "localsip/somleng:latest"
}

variable "switch_image" {
  description = "Docker image for Somleng Switch"
  type        = string
  default     = "localsip/switch:latest"
}

variable "freeswitch_image" {
  description = "Docker image for FreeSWITCH"
  type        = string
  default     = "localsip/freeswitch:latest"
}

variable "rating_engine_image" {
  description = "Docker image for Rating Engine (CGRates)"
  type        = string
  default     = "localsip/rating-engine:latest"
}

variable "anycable_ws_image" {
  description = "Docker image for AnyCable WebSocket server"
  type        = string
  default     = "anycable/anycable-go:latest-alpine"
}

variable "postgres_image" {
  description = "Docker image for PostgreSQL (when deployed in-cluster)"
  type        = string
  default     = "postgres:alpine"
}

variable "redis_image" {
  description = "Docker image for Redis (when deployed in-cluster)"
  type        = string
  default     = "redis:alpine"
}

variable "image_pull_policy" {
  description = "Image pull policy for all deployments"
  type        = string
  default     = "Always"
}

variable "image_pull_secret_name" {
  description = "Name of the Kubernetes docker-registry secret for pulling images from a private registry. Leave empty for public images."
  type        = string
  default     = ""
}

# =============================================================================
# Optional Infrastructure Services
# =============================================================================

variable "deploy_postgres" {
  description = "Deploy PostgreSQL as a K8s pod. Set false when using managed DB (RDS, Cloud SQL, etc.)"
  type        = bool
  default     = true
}

variable "deploy_redis" {
  description = "Deploy Redis as a K8s pod. Set false when using managed Redis (ElastiCache, etc.)"
  type        = bool
  default     = true
}

# =============================================================================
# Database Configuration
# =============================================================================

variable "database_host" {
  description = "Database hostname. Leave empty when deploy_postgres=true (auto-computed)."
  type        = string
  default     = ""
}

variable "database_username" {
  description = "Database username"
  type        = string
  default     = "somleng"
}

# =============================================================================
# Redis Configuration
# =============================================================================

variable "redis_host" {
  description = "Redis hostname. Leave empty when deploy_redis=true (auto-computed)."
  type        = string
  default     = ""
}

variable "redis_port" {
  description = "Redis port"
  type        = number
  default     = 6379
}

# =============================================================================
# Domains / Networking
# =============================================================================

variable "api_domain" {
  description = "Domain for the Somleng API (Ingress host)"
  type        = string
  default     = "api.yourdomain.com"
}

variable "ws_domain" {
  description = "Domain for the AnyCable WebSocket endpoint (Ingress host)"
  type        = string
  default     = "ws.yourdomain.com"
}

variable "dashboard_url_host" {
  description = "Full URL for the dashboard"
  type        = string
  default     = "https://dashboard.yourdomain.com"
}

# =============================================================================
# FreeSWITCH
# =============================================================================

variable "fs_external_sip_ip" {
  description = "Public IP for FreeSWITCH SIP signaling"
  type        = string
}

variable "fs_external_rtp_ip" {
  description = "Public IP for FreeSWITCH RTP media"
  type        = string
}

variable "freeswitch_node_selector" {
  description = "Node selector for FreeSWITCH pods (node must have these labels)"
  type        = map(string)
  default     = { "somleng/role" = "media" }
}

# =============================================================================
# Secrets (all sensitive)
# =============================================================================

variable "postgres_password" {
  description = "PostgreSQL password"
  type        = string
  sensitive   = true
}

variable "secret_key_base" {
  description = "Rails SECRET_KEY_BASE"
  type        = string
  sensitive   = true
}

variable "fs_esl_password" {
  description = "FreeSWITCH ESL password"
  type        = string
  sensitive   = true
}

variable "anycable_secret" {
  description = "AnyCable secret key"
  type        = string
  sensitive   = true
}

variable "rating_engine_password" {
  description = "Rating engine JSON-RPC password"
  type        = string
  sensitive   = true
}

# =============================================================================
# Storage
# =============================================================================

variable "postgres_storage_size" {
  description = "Storage size for PostgreSQL PVC"
  type        = string
  default     = "20Gi"
}

variable "postgres_storage_class" {
  description = "StorageClass for PostgreSQL PVC (empty = cluster default)"
  type        = string
  default     = ""
}

variable "sip_gateways_storage_class" {
  description = "StorageClass for sip-gateways PVC (must support ReadWriteMany)"
  type        = string
  default     = ""
}

variable "sip_gateways_storage_size" {
  description = "Storage size for sip-gateways PVC"
  type        = string
  default     = "100Mi"
}

# =============================================================================
# Ingress
# =============================================================================

variable "deploy_ingress" {
  description = "Deploy the Ingress resource"
  type        = bool
  default     = true
}

variable "ingress_class_name" {
  description = "Ingress class name (e.g., nginx, traefik)"
  type        = string
  default     = null
}

variable "ingress_annotations" {
  description = "Additional annotations for the Ingress resource"
  type        = map(string)
  default     = {}
}

variable "ingress_tls_secret_name" {
  description = "TLS secret name for Ingress. Empty = no TLS."
  type        = string
  default     = ""
}

# =============================================================================
# Replicas / Scaling
# =============================================================================

variable "somleng_api_replicas" {
  description = "Number of Somleng API replicas"
  type        = number
  default     = 2
}

# =============================================================================
# Application Config
# =============================================================================

variable "rails_env" {
  description = "Rails environment"
  type        = string
  default     = "production"
}

variable "stub_rating_engine" {
  description = "Set to true to stub the rating engine"
  type        = bool
  default     = false
}
