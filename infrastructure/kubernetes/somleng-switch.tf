resource "kubernetes_deployment_v1" "somleng_switch" {
  metadata {
    name      = "somleng-switch"
    namespace = kubernetes_namespace_v1.somleng.metadata[0].name
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "somleng-switch"
      }
    }

    template {
      metadata {
        labels = {
          app = "somleng-switch"
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
          name              = "somleng-switch"
          image             = var.switch_image
          image_pull_policy = var.image_pull_policy

          port {
            container_port = 8080
          }

          env {
            name = "AHN_CORE_HOST"
            value_from {
              config_map_key_ref {
                name = kubernetes_config_map_v1.somleng_config.metadata[0].name
                key  = "FS_ESL_HOST"
              }
            }
          }

          env {
            name  = "AHN_CORE_HTTP_PORT"
            value = "8080"
          }

          env {
            name  = "CALL_PLATFORM_HOST"
            value = "http://${local.somleng_api_host}:3000"
          }

          env {
            name = "REDIS_URL"
            value_from {
              config_map_key_ref {
                name = kubernetes_config_map_v1.somleng_config.metadata[0].name
                key  = "REDIS_URL_SWITCH"
              }
            }
          }

          env {
            name = "SIP_GATEWAY_DIR"
            value_from {
              config_map_key_ref {
                name = kubernetes_config_map_v1.somleng_config.metadata[0].name
                key  = "SIP_GATEWAY_DIR"
              }
            }
          }

          env {
            name = "FS_ESL_HOST"
            value_from {
              config_map_key_ref {
                name = kubernetes_config_map_v1.somleng_config.metadata[0].name
                key  = "FS_ESL_HOST"
              }
            }
          }

          env {
            name = "FS_ESL_PORT"
            value_from {
              config_map_key_ref {
                name = kubernetes_config_map_v1.somleng_config.metadata[0].name
                key  = "FS_ESL_PORT"
              }
            }
          }

          env {
            name = "FS_ESL_PASSWORD"
            value_from {
              secret_key_ref {
                name = kubernetes_secret_v1.somleng_secrets.metadata[0].name
                key  = "FS_ESL_PASSWORD"
              }
            }
          }

          volume_mount {
            name       = "sip-gateways"
            mount_path = "/sip_gateways"
          }

          readiness_probe {
            http_get {
              path = "/health_checks"
              port = 8080
            }
            initial_delay_seconds = 10
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

        volume {
          name = "sip-gateways"
          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim_v1.sip_gateways.metadata[0].name
          }
        }
      }
    }
  }
}

resource "kubernetes_service_v1" "somleng_switch" {
  metadata {
    name      = "somleng-switch"
    namespace = kubernetes_namespace_v1.somleng.metadata[0].name
  }

  spec {
    selector = {
      app = "somleng-switch"
    }

    port {
      port        = 8080
      target_port = 8080
    }
  }
}
