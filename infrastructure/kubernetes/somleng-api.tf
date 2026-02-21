resource "kubernetes_deployment_v1" "somleng_api" {
  metadata {
    name      = "somleng-api"
    namespace = kubernetes_namespace_v1.somleng.metadata[0].name
  }

  spec {
    replicas = var.somleng_api_replicas

    selector {
      match_labels = {
        app = "somleng-api"
      }
    }

    template {
      metadata {
        labels = {
          app = "somleng-api"
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
          name              = "somleng-api"
          image             = var.somleng_image
          image_pull_policy = var.image_pull_policy
          command           = ["./bin/rails", "server", "-b", "0.0.0.0", "-e", "production"]

          port {
            container_port = 3000
          }

          env_from {
            config_map_ref {
              name = kubernetes_config_map_v1.somleng_config.metadata[0].name
            }
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

          env {
            name = "RATING_ENGINE_PASSWORD"
            value_from {
              secret_key_ref {
                name = kubernetes_secret_v1.somleng_secrets.metadata[0].name
                key  = "RATING_ENGINE_PASSWORD"
              }
            }
          }

          env {
            name = "CALL_SERVICE_DEFAULT_HOST"
            value_from {
              config_map_key_ref {
                name = kubernetes_config_map_v1.somleng_config.metadata[0].name
                key  = "SWITCH_HOST"
              }
            }
          }

          readiness_probe {
            http_get {
              path = "/health_checks"
              port = 3000
            }
            initial_delay_seconds = 15
            period_seconds        = 10
          }

          liveness_probe {
            http_get {
              path = "/health_checks"
              port = 3000
            }
            initial_delay_seconds = 30
            period_seconds        = 20
          }

          resources {
            requests = {
              cpu    = "500m"
              memory = "512Mi"
            }
            limits = {
              cpu    = "1"
              memory = "1Gi"
            }
          }
        }
      }
    }
  }
}

resource "kubernetes_service_v1" "somleng_api" {
  metadata {
    name      = "somleng-api"
    namespace = kubernetes_namespace_v1.somleng.metadata[0].name
  }

  spec {
    selector = {
      app = "somleng-api"
    }

    port {
      port        = 3000
      target_port = 3000
    }
  }
}
