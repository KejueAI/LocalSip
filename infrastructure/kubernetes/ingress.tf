resource "kubernetes_ingress_v1" "somleng" {
  count = var.deploy_ingress ? 1 : 0

  metadata {
    name        = "somleng"
    namespace   = kubernetes_namespace_v1.somleng.metadata[0].name
    annotations = var.ingress_annotations
  }

  spec {
    ingress_class_name = var.ingress_class_name

    dynamic "tls" {
      for_each = var.ingress_tls_secret_name != "" ? [1] : []
      content {
        hosts       = [var.api_domain, var.ws_domain]
        secret_name = var.ingress_tls_secret_name
      }
    }

    rule {
      host = var.api_domain
      http {
        path {
          path      = "/"
          path_type = "Prefix"
          backend {
            service {
              name = kubernetes_service_v1.somleng_api.metadata[0].name
              port {
                number = 3000
              }
            }
          }
        }
      }
    }

    rule {
      host = var.ws_domain
      http {
        path {
          path      = "/"
          path_type = "Prefix"
          backend {
            service {
              name = kubernetes_service_v1.anycable_ws.metadata[0].name
              port {
                number = 8080
              }
            }
          }
        }
      }
    }
  }
}
