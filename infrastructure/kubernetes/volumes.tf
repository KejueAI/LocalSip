resource "kubernetes_persistent_volume_claim_v1" "postgres_data" {
  count = var.deploy_postgres ? 1 : 0

  metadata {
    name      = "postgres-data"
    namespace = kubernetes_namespace_v1.somleng.metadata[0].name
  }

  spec {
    access_modes       = ["ReadWriteOnce"]
    storage_class_name = var.postgres_storage_class != "" ? var.postgres_storage_class : null

    resources {
      requests = {
        storage = var.postgres_storage_size
      }
    }
  }
}

resource "kubernetes_persistent_volume_claim_v1" "sip_gateways" {
  metadata {
    name      = "sip-gateways"
    namespace = kubernetes_namespace_v1.somleng.metadata[0].name
  }

  spec {
    access_modes       = ["ReadWriteMany"]
    storage_class_name = var.sip_gateways_storage_class != "" ? var.sip_gateways_storage_class : null

    resources {
      requests = {
        storage = var.sip_gateways_storage_size
      }
    }
  }
}
