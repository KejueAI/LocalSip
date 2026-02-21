resource "kubernetes_config_map_v1" "somleng_config" {
  metadata {
    name      = "somleng-config"
    namespace = kubernetes_namespace_v1.somleng.metadata[0].name
  }

  data = {
    # SIP / RTP
    FS_EXTERNAL_SIP_IP = var.fs_external_sip_ip
    FS_EXTERNAL_RTP_IP = var.fs_external_rtp_ip

    # Database
    DATABASE_HOST     = local.effective_database_host
    DATABASE_USERNAME = var.database_username
    POSTGRES_USER     = var.database_username

    # Redis
    REDIS_URL        = local.redis_url
    REDIS_URL_SWITCH = local.redis_url_switch

    # Somleng API
    RAILS_ENV          = var.rails_env
    SOMLENG_API_HOST   = local.somleng_api_host
    SOMLENG_API_PORT   = "3000"
    DASHBOARD_URL_HOST = var.dashboard_url_host
    DB_POOL            = "30"

    # Switch
    SWITCH_HOST     = "http://${local.switch_host}:8080"
    FS_ESL_HOST     = local.freeswitch_host
    FS_ESL_PORT     = "8021"
    SIP_GATEWAY_DIR = "/sip_gateways"

    # Rating Engine
    RATING_ENGINE_HOST     = "http://${local.rating_engine_host}:2080"
    RATING_ENGINE_USERNAME = "cgrates"
    STUB_RATING_ENGINE     = tostring(var.stub_rating_engine)
    STORDB_DBNAME          = "cgrates"

    # AnyCable
    ANYCABLE_BROADCAST_ADAPTER = "redisx"
  }
}

resource "kubernetes_config_map_v1" "freeswitch_profiles" {
  metadata {
    name      = "freeswitch-profiles"
    namespace = kubernetes_namespace_v1.somleng.metadata[0].name
  }

  data = {
    "nat_gateway.xml" = <<-XML
    <profile name="nat_gateway">
      <gateways>
        <X-PRE-PROCESS cmd="include" data="nat_gateway/*.xml"/>
      </gateways>
      <settings>
        <X-PRE-PROCESS cmd="include" data="shared/settings.xml"/>
        <param name="sip-port" value="$${ext_profile_nat_gateway_sip_port}"/>
        <param name="ext-sip-ip" value="$${external_sip_ip}"/>
        <param name="ext-rtp-ip" value="$${external_rtp_ip}"/>
      </settings>
    </profile>
    XML
  }
}

resource "kubernetes_config_map_v1" "init_db_sql" {
  count = var.deploy_postgres ? 1 : 0

  metadata {
    name      = "init-db-sql"
    namespace = kubernetes_namespace_v1.somleng.metadata[0].name
  }

  data = {
    "init-db.sql" = "CREATE DATABASE freeswitch;"
  }
}
