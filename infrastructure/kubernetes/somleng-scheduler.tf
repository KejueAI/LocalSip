resource "kubernetes_deployment_v1" "somleng_scheduler" {
  metadata {
    name      = "somleng-scheduler"
    namespace = kubernetes_namespace_v1.somleng.metadata[0].name
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "somleng-scheduler"
      }
    }

    template {
      metadata {
        labels = {
          app = "somleng-scheduler"
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
          name              = "somleng-scheduler"
          image             = var.somleng_image
          image_pull_policy = var.image_pull_policy
          command           = ["/bin/sh", "-c", "while true; do bundle exec rails runner 'PerMinuteJob.perform_later'; sleep 60; done"]

          env_from {
            config_map_ref {
              name = kubernetes_config_map_v1.somleng_config.metadata[0].name
            }
          }

          env {
            name  = "ACTIVE_JOB_QUEUE_ADAPTER"
            value = "inline"
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
