resource "kubernetes_deployment_v1" "freeswitch" {
  metadata {
    name      = "freeswitch"
    namespace = kubernetes_namespace_v1.somleng.metadata[0].name
  }

  spec {
    replicas = 1

    strategy {
      type = "Recreate"
    }

    selector {
      match_labels = {
        app = "freeswitch"
      }
    }

    template {
      metadata {
        labels = {
          app = "freeswitch"
        }
      }

      spec {
        host_network = true
        dns_policy   = "ClusterFirstWithHostNet"

        node_selector = var.freeswitch_node_selector

        dynamic "image_pull_secrets" {
          for_each = var.image_pull_secret_name != "" ? [var.image_pull_secret_name] : []
          content {
            name = image_pull_secrets.value
          }
        }

        container {
          name              = "freeswitch"
          image             = var.freeswitch_image
          image_pull_policy = var.image_pull_policy

          env {
            name = "FS_DATABASE_HOST"
            value_from {
              config_map_key_ref {
                name = kubernetes_config_map_v1.somleng_config.metadata[0].name
                key  = "DATABASE_HOST"
              }
            }
          }

          env {
            name = "FS_DATABASE_PASSWORD"
            value_from {
              secret_key_ref {
                name = kubernetes_secret_v1.somleng_secrets.metadata[0].name
                key  = "POSTGRES_PASSWORD"
              }
            }
          }

          env {
            name  = "FS_MOD_JSON_CDR_URL"
            value = "http://${local.somleng_api_host}:3000/services/call_data_records"
          }

          env {
            name = "FS_EXTERNAL_SIP_IP"
            value_from {
              config_map_key_ref {
                name = kubernetes_config_map_v1.somleng_config.metadata[0].name
                key  = "FS_EXTERNAL_SIP_IP"
              }
            }
          }

          env {
            name = "FS_EXTERNAL_RTP_IP"
            value_from {
              config_map_key_ref {
                name = kubernetes_config_map_v1.somleng_config.metadata[0].name
                key  = "FS_EXTERNAL_RTP_IP"
              }
            }
          }

          volume_mount {
            name       = "nat-gateway-profile"
            mount_path = "/etc/freeswitch/sip_profiles/nat_gateway.xml"
            sub_path   = "nat_gateway.xml"
          }

          volume_mount {
            name       = "sip-gateways"
            mount_path = "/etc/freeswitch/sip_profiles/nat_gateway"
          }

          liveness_probe {
            tcp_socket {
              port = 5222
            }
            initial_delay_seconds = 15
            period_seconds        = 20
          }

          readiness_probe {
            tcp_socket {
              port = 5222
            }
            initial_delay_seconds = 5
            period_seconds        = 10
          }

          resources {
            requests = {
              cpu    = "500m"
              memory = "512Mi"
            }
            limits = {
              cpu    = "2"
              memory = "2Gi"
            }
          }
        }

        volume {
          name = "nat-gateway-profile"
          config_map {
            name = kubernetes_config_map_v1.freeswitch_profiles.metadata[0].name
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

# Headless service for DNS resolution.
# Since FreeSWITCH uses hostNetwork, the pod IP = node IP.
resource "kubernetes_service_v1" "freeswitch" {
  metadata {
    name      = "freeswitch"
    namespace = kubernetes_namespace_v1.somleng.metadata[0].name
  }

  spec {
    selector = {
      app = "freeswitch"
    }

    cluster_ip = "None"

    port {
      name        = "sip"
      port        = 5060
      protocol    = "UDP"
      target_port = 5060
    }

    port {
      name        = "esl"
      port        = 8021
      protocol    = "TCP"
      target_port = 8021
    }

    port {
      name        = "health"
      port        = 5222
      protocol    = "TCP"
      target_port = 5222
    }
  }
}
