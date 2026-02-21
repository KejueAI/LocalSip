# =============================================================================
# AnyCable RPC (Ruby gRPC server)
# =============================================================================

resource "kubernetes_deployment_v1" "anycable_rpc" {
  metadata {
    name      = "anycable-rpc"
    namespace = kubernetes_namespace_v1.somleng.metadata[0].name
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "anycable-rpc"
      }
    }

    template {
      metadata {
        labels = {
          app = "anycable-rpc"
        }
      }

      spec {
        dynamic "image_pull_secrets" {
          for_each = var.image_pull_secret_name != "" ? [var.image_pull_secret_name] : []
          content {
            name = image_pull_secrets.value
          }
        }

        container {
          name              = "anycable-rpc"
          image             = var.somleng_image
          image_pull_policy = var.image_pull_policy
          command           = ["bundle", "exec", "anycable"]

          port {
            container_port = 50051
          }

          env_from {
            config_map_ref {
              name = kubernetes_config_map_v1.somleng_config.metadata[0].name
            }
          }

          env {
            name  = "ANYCABLE_RPC_HOST"
            value = "0.0.0.0:50051"
          }

          env {
            name = "DATABASE_PASSWORD"
            value_from {
              secret_key_ref {
                name = kubernetes_secret_v1.somleng_secrets.metadata[0].name
                key  = "POSTGRES_PASSWORD"
              }
            }
          }

          env {
            name = "SECRET_KEY_BASE"
            value_from {
              secret_key_ref {
                name = kubernetes_secret_v1.somleng_secrets.metadata[0].name
                key  = "SECRET_KEY_BASE"
              }
            }
          }

          env {
            name = "ANYCABLE_SECRET"
            value_from {
              secret_key_ref {
                name = kubernetes_secret_v1.somleng_secrets.metadata[0].name
                key  = "ANYCABLE_SECRET"
              }
            }
          }

          readiness_probe {
            exec {
              command = ["grpc-health-probe", "-addr", ":50051"]
            }
            initial_delay_seconds = 10
            period_seconds        = 10
          }

          resources {
            requests = {
              cpu    = "100m"
              memory = "256Mi"
            }
            limits = {
              cpu    = "500m"
              memory = "512Mi"
            }
          }
        }
      }
    }
  }
}

resource "kubernetes_service_v1" "anycable_rpc" {
  metadata {
    name      = "anycable-rpc"
    namespace = kubernetes_namespace_v1.somleng.metadata[0].name
  }

  spec {
    selector = {
      app = "anycable-rpc"
    }

    port {
      port        = 50051
      target_port = 50051
    }
  }
}

# =============================================================================
# AnyCable WebSocket (Go server)
# =============================================================================

resource "kubernetes_deployment_v1" "anycable_ws" {
  metadata {
    name      = "anycable-ws"
    namespace = kubernetes_namespace_v1.somleng.metadata[0].name
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "anycable-ws"
      }
    }

    template {
      metadata {
        labels = {
          app = "anycable-ws"
        }
      }

      spec {
        dynamic "image_pull_secrets" {
          for_each = var.image_pull_secret_name != "" ? [var.image_pull_secret_name] : []
          content {
            name = image_pull_secrets.value
          }
        }

        container {
          name              = "anycable-ws"
          image             = var.anycable_ws_image
          image_pull_policy = var.image_pull_policy

          port {
            container_port = 8080
          }

          env {
            name = "REDIS_URL"
            value_from {
              config_map_key_ref {
                name = kubernetes_config_map_v1.somleng_config.metadata[0].name
                key  = "REDIS_URL"
              }
            }
          }

          env {
            name  = "ANYCABLE_HOST"
            value = "0.0.0.0"
          }

          env {
            name  = "ANYCABLE_PORT"
            value = "8080"
          }

          env {
            name  = "ANYCABLE_DISABLE_TELEMETRY"
            value = "true"
          }

          env {
            name  = "ANYCABLE_RPC_HOST"
            value = "${local.anycable_rpc_host}:50051"
          }

          env {
            name  = "ANYCABLE_BROADCAST_ADAPTER"
            value = "redisx"
          }

          env {
            name  = "ANYCABLE_BROKER"
            value = "memory"
          }

          env {
            name  = "ANYCABLE_PUBSUB"
            value = "redis"
          }

          env {
            name  = "ANYCABLE_HEADERS"
            value = "x-device-key"
          }

          env {
            name  = "ANYCABLE_HEALTH_PATH"
            value = "/health"
          }

          env {
            name  = "ANYCABLE_LOG_LEVEL"
            value = "info"
          }

          env {
            name  = "ANYCABLE_LOG_FORMAT"
            value = "json"
          }

          env {
            name = "ANYCABLE_SECRET"
            value_from {
              secret_key_ref {
                name = kubernetes_secret_v1.somleng_secrets.metadata[0].name
                key  = "ANYCABLE_SECRET"
              }
            }
          }

          readiness_probe {
            http_get {
              path = "/health"
              port = 8080
            }
            initial_delay_seconds = 5
            period_seconds        = 10
          }

          resources {
            requests = {
              cpu    = "100m"
              memory = "128Mi"
            }
            limits = {
              cpu    = "500m"
              memory = "256Mi"
            }
          }
        }
      }
    }
  }
}

resource "kubernetes_service_v1" "anycable_ws" {
  metadata {
    name      = "anycable-ws"
    namespace = kubernetes_namespace_v1.somleng.metadata[0].name
  }

  spec {
    selector = {
      app = "anycable-ws"
    }

    port {
      port        = 8080
      target_port = 8080
    }
  }
}
