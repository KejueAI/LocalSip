resource "kubernetes_namespace_v1" "somleng" {
  metadata {
    name = var.namespace
  }
}
