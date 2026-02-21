resource "kubernetes_secret_v1" "somleng_secrets" {
  metadata {
    name      = "somleng-secrets"
    namespace = kubernetes_namespace_v1.somleng.metadata[0].name
  }

  type = "Opaque"

  data = {
    POSTGRES_PASSWORD      = var.postgres_password
    SECRET_KEY_BASE        = var.secret_key_base
    FS_ESL_PASSWORD        = var.fs_esl_password
    ANYCABLE_SECRET        = var.anycable_secret
    RATING_ENGINE_PASSWORD = var.rating_engine_password
  }
}
