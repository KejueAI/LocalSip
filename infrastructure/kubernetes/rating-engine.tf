resource "kubernetes_deployment_v1" "rating_engine" {
  metadata {
    name      = "rating-engine"
    namespace = kubernetes_namespace_v1.somleng.metadata[0].name
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "rating-engine"
      }
    }

    template {
      metadata {
        labels = {
          app = "rating-engine"
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
          name              = "rating-engine"
          image             = var.rating_engine_image
          image_pull_policy = var.image_pull_policy

          port {
            container_port = 2080
          }

          env {
            name = "STORDB_DBNAME"
            value_from {
              config_map_key_ref {
                name = kubernetes_config_map_v1.somleng_config.metadata[0].name
                key  = "STORDB_DBNAME"
              }
            }
          }

          env {
            name = "STORDB_USER"
            value_from {
              config_map_key_ref {
                name = kubernetes_config_map_v1.somleng_config.metadata[0].name
                key  = "POSTGRES_USER"
              }
            }
          }

          env {
            name = "STORDB_PASSWORD"
            value_from {
              secret_key_ref {
                name = kubernetes_secret_v1.somleng_secrets.metadata[0].name
                key  = "POSTGRES_PASSWORD"
              }
            }
          }

          env {
            name = "STORDB_HOST"
            value_from {
              config_map_key_ref {
                name = kubernetes_config_map_v1.somleng_config.metadata[0].name
                key  = "DATABASE_HOST"
              }
            }
          }

          env {
            name  = "STORDB_PORT"
            value = "5432"
          }

          env {
            name  = "DATADB_HOST"
            value = local.effective_redis_host
          }

          env {
            name  = "DATADB_USER"
            value = ""
          }

          env {
            name  = "DATADB_PORT"
            value = tostring(var.redis_port)
          }

          env {
            name  = "DATADB_DBNAME"
            value = "2"
          }

          env {
            name  = "CONNECTION_MODE"
            value = "*localhost"
          }

          env {
            name  = "LOG_LEVEL"
            value = "7"
          }

          env {
            name  = "HTTP_LISTEN_ADDRESS"
            value = "0.0.0.0:2080"
          }

          env {
            name  = "BOOTSTRAP_DB"
            value = "true"
          }

          env {
            name  = "SERVER_MODE"
            value = "api"
          }

          env {
            name = "JSON_RPC_USERNAME"
            value_from {
              config_map_key_ref {
                name = kubernetes_config_map_v1.somleng_config.metadata[0].name
                key  = "RATING_ENGINE_USERNAME"
              }
            }
          }

          env {
            name = "JSON_RPC_PASSWORD"
            value_from {
              secret_key_ref {
                name = kubernetes_secret_v1.somleng_secrets.metadata[0].name
                key  = "RATING_ENGINE_PASSWORD"
              }
            }
          }

          readiness_probe {
            exec {
              command = ["/usr/local/bin/docker-healthcheck.sh"]
            }
            initial_delay_seconds = 15
            period_seconds        = 10
          }

          resources {
            requests = {
              cpu    = "250m"
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

resource "kubernetes_service_v1" "rating_engine" {
  metadata {
    name      = "rating-engine"
    namespace = kubernetes_namespace_v1.somleng.metadata[0].name
  }

  spec {
    selector = {
      app = "rating-engine"
    }

    port {
      port        = 2080
      target_port = 2080
    }
  }
}
