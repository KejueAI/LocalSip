# =============================================================================
# ECS Cluster + Application Services
# Deploys patched Somleng images into the hydrogen region.
# =============================================================================

data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

locals {
  ecr_base = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${data.aws_region.current.name}.amazonaws.com"

  # Redis is deployed as ElastiCache in production.
  # This variable should be overridden with the actual ElastiCache endpoint.
  redis_endpoint = var.redis_endpoint

  # Internal service discovery hostnames
  somleng_api_host = "somleng-api.${module.ecs_cluster.service_discovery_namespace.name}"
  switch_host      = "somleng-switch.${module.ecs_cluster.service_discovery_namespace.name}"
  freeswitch_host  = "freeswitch.${module.ecs_cluster.service_discovery_namespace.name}"
  rating_host      = "rating-engine.${module.ecs_cluster.service_discovery_namespace.name}"
}

# -----------------------------------------------------------------------------
# ECS Cluster
# -----------------------------------------------------------------------------
module "ecs_cluster" {
  source = "../modules/ecs_cluster"

  name   = "somleng"
  region = module.hydrogen_region
}

# -----------------------------------------------------------------------------
# Somleng API (patched)
# Runs the Rails API server behind the public ALB.
# -----------------------------------------------------------------------------
module "somleng_api" {
  source = "../modules/ecs_service"

  name           = "somleng-api"
  cluster        = module.ecs_cluster
  region         = module.hydrogen_region
  image          = "${local.ecr_base}/somleng:latest"
  container_port = 3000
  cpu            = 1024
  memory         = 2048
  desired_count  = 2
  command        = ["./bin/rails", "server", "-b", "0.0.0.0", "-e", "production"]

  load_balancer     = module.hydrogen_region.public_load_balancer
  listener_priority = 100
  host_header       = ["api.somleng.org", "*.app.somleng.org"]
  health_check_path = "/health_checks"

  environment = {
    RAILS_ENV                  = "production"
    DATABASE_HOST              = module.db.this.endpoint
    DATABASE_USERNAME          = "somleng"
    DB_POOL                    = "30"
    REDIS_URL                  = "redis://${local.redis_endpoint}:6379/0"
    SWITCH_HOST                = "http://${local.switch_host}:8080"
    CALL_SERVICE_DEFAULT_HOST  = "http://${local.switch_host}:8080"
    DASHBOARD_URL_HOST         = "https://dashboard.somleng.org"
    ANYCABLE_BROADCAST_ADAPTER = "redisx"
    RATING_ENGINE_HOST         = "http://${local.rating_host}:2080"
    RATING_ENGINE_USERNAME     = "cgrates"
    STUB_RATING_ENGINE         = "false"
  }

  secrets = {
    DATABASE_PASSWORD  = module.db.master_password_parameter.arn
    SECRET_KEY_BASE    = aws_ssm_parameter.rails_secret_key_base.arn
    ANYCABLE_SECRET    = aws_ssm_parameter.anycable_secret.arn
    RATING_ENGINE_PASSWORD = aws_ssm_parameter.rating_engine_password.arn
  }

  additional_security_group_ids = [module.db.security_group.id]
}

# -----------------------------------------------------------------------------
# Somleng Scheduler
# Runs periodic jobs (PerMinuteJob) in the background.
# -----------------------------------------------------------------------------
module "somleng_scheduler" {
  source = "../modules/ecs_service"

  name           = "somleng-scheduler"
  cluster        = module.ecs_cluster
  region         = module.hydrogen_region
  image          = "${local.ecr_base}/somleng:latest"
  container_port = 3000
  cpu            = 256
  memory         = 512
  desired_count  = 1
  command        = ["/bin/sh", "-c", "while true; do bundle exec rails runner 'PerMinuteJob.perform_later'; sleep 60; done"]

  enable_service_discovery = false

  environment = {
    RAILS_ENV                  = "production"
    DATABASE_HOST              = module.db.this.endpoint
    DATABASE_USERNAME          = "somleng"
    DB_POOL                    = "5"
    REDIS_URL                  = "redis://${local.redis_endpoint}:6379/0"
    SWITCH_HOST                = "http://${local.switch_host}:8080"
    CALL_SERVICE_DEFAULT_HOST  = "http://${local.switch_host}:8080"
    ACTIVE_JOB_QUEUE_ADAPTER   = "inline"
    ANYCABLE_BROADCAST_ADAPTER = "redisx"
    RATING_ENGINE_HOST         = "http://${local.rating_host}:2080"
    RATING_ENGINE_USERNAME     = "cgrates"
    STUB_RATING_ENGINE         = "false"
  }

  secrets = {
    DATABASE_PASSWORD      = module.db.master_password_parameter.arn
    SECRET_KEY_BASE        = aws_ssm_parameter.rails_secret_key_base.arn
    ANYCABLE_SECRET        = aws_ssm_parameter.anycable_secret.arn
    RATING_ENGINE_PASSWORD = aws_ssm_parameter.rating_engine_password.arn
  }

  additional_security_group_ids = [module.db.security_group.id]
}

# -----------------------------------------------------------------------------
# AnyCable RPC
# gRPC server for AnyCable WebSocket connections.
# -----------------------------------------------------------------------------
module "anycable_rpc" {
  source = "../modules/ecs_service"

  name           = "anycable-rpc"
  cluster        = module.ecs_cluster
  region         = module.hydrogen_region
  image          = "${local.ecr_base}/somleng:latest"
  container_port = 50051
  cpu            = 256
  memory         = 512
  desired_count  = 1
  command        = ["bundle", "exec", "anycable"]

  environment = {
    RAILS_ENV                  = "production"
    DATABASE_HOST              = module.db.this.endpoint
    DATABASE_USERNAME          = "somleng"
    DB_POOL                    = "5"
    REDIS_URL                  = "redis://${local.redis_endpoint}:6379/0"
    ANYCABLE_RPC_HOST          = "0.0.0.0:50051"
    ANYCABLE_BROADCAST_ADAPTER = "redisx"
  }

  secrets = {
    DATABASE_PASSWORD = module.db.master_password_parameter.arn
    SECRET_KEY_BASE   = aws_ssm_parameter.rails_secret_key_base.arn
    ANYCABLE_SECRET   = aws_ssm_parameter.anycable_secret.arn
  }

  additional_security_group_ids = [module.db.security_group.id]
}

# -----------------------------------------------------------------------------
# AnyCable WebSocket (Go)
# Handles WebSocket connections from clients.
# -----------------------------------------------------------------------------
module "anycable_ws" {
  source = "../modules/ecs_service"

  name           = "anycable-ws"
  cluster        = module.ecs_cluster
  region         = module.hydrogen_region
  image          = "anycable/anycable-go:latest-alpine"
  container_port = 8080
  cpu            = 256
  memory         = 512
  desired_count  = 1

  load_balancer     = module.hydrogen_region.public_load_balancer
  listener_priority = 200
  host_header       = ["ws.somleng.org"]
  health_check_path = "/health"

  environment = {
    REDIS_URL                  = "redis://${local.redis_endpoint}:6379/0"
    ANYCABLE_HOST              = "0.0.0.0"
    ANYCABLE_PORT              = "8080"
    ANYCABLE_DISABLE_TELEMETRY = "true"
    ANYCABLE_RPC_HOST          = "anycable-rpc.${module.ecs_cluster.service_discovery_namespace.name}:50051"
    ANYCABLE_BROADCAST_ADAPTER = "redisx"
    ANYCABLE_BROKER            = "memory"
    ANYCABLE_PUBSUB            = "redis"
    ANYCABLE_HEADERS           = "x-device-key"
    ANYCABLE_HEALTH_PATH       = "/health"
    ANYCABLE_LOG_LEVEL         = "info"
    ANYCABLE_LOG_FORMAT        = "json"
  }

  secrets = {
    ANYCABLE_SECRET = aws_ssm_parameter.anycable_secret.arn
  }
}

# -----------------------------------------------------------------------------
# Somleng Switch (patched)
# Adhearsion app that manages FreeSWITCH and SIP gateways.
# -----------------------------------------------------------------------------
module "somleng_switch" {
  source = "../modules/ecs_service"

  name           = "somleng-switch"
  cluster        = module.ecs_cluster
  region         = module.hydrogen_region
  image          = "${local.ecr_base}/switch:latest"
  container_port = 8080
  cpu            = 512
  memory         = 1024
  desired_count  = 1

  load_balancer     = module.hydrogen_region.internal_load_balancer
  listener_priority = 100
  host_header       = ["switch.hydrogen.somleng.org", "switch.internal.somleng.org"]
  health_check_path = "/health_checks"

  environment = {
    AHN_CORE_HOST      = local.freeswitch_host
    AHN_CORE_HTTP_PORT = "8080"
    CALL_PLATFORM_HOST = "http://${local.somleng_api_host}:3000"
    REDIS_URL          = "redis://${local.redis_endpoint}:6379/1"
    SIP_GATEWAY_DIR    = "/sip_gateways"
    FS_ESL_HOST        = local.freeswitch_host
    FS_ESL_PORT        = "8021"
  }

  secrets = {
    FS_ESL_PASSWORD = aws_ssm_parameter.fs_esl_password.arn
  }

  volumes = [
    {
      name = "sip-gateways"
      efs_volume_configuration = {
        file_system_id = aws_efs_file_system.sip_gateways.id
      }
    }
  ]

  mount_points = [
    {
      sourceVolume  = "sip-gateways"
      containerPath = "/sip_gateways"
    }
  ]

  additional_security_group_ids = [aws_security_group.efs_sip_gateways.id]
}

# -----------------------------------------------------------------------------
# FreeSWITCH
# SIP/RTP media gateway. Needs public IP for SIP signaling and media.
# Uses the NAT instance EIP as its external SIP/RTP address.
# -----------------------------------------------------------------------------
module "freeswitch" {
  source = "../modules/ecs_service"

  name              = "freeswitch"
  cluster           = module.ecs_cluster
  region            = module.hydrogen_region
  image             = "${local.ecr_base}/freeswitch:latest"
  container_port    = 5222 # health check port
  cpu               = 1024
  memory            = 2048
  desired_count     = 1
  use_public_subnets = false
  health_check_path = "/"

  enable_service_discovery = true

  udp_ports = [5060]

  environment = {
    FS_DATABASE_HOST    = module.db.this.endpoint
    FS_MOD_JSON_CDR_URL = "http://${local.somleng_api_host}:3000/services/call_data_records"
    FS_EXTERNAL_SIP_IP  = module.hydrogen_region.nat_instance.public_ip
    FS_EXTERNAL_RTP_IP  = module.hydrogen_region.nat_instance.public_ip
  }

  secrets = {
    FS_DATABASE_PASSWORD = module.db.master_password_parameter.arn
  }

  volumes = [
    {
      name = "sip-gateways"
      efs_volume_configuration = {
        file_system_id = aws_efs_file_system.sip_gateways.id
      }
    }
  ]

  mount_points = [
    {
      sourceVolume  = "sip-gateways"
      containerPath = "/etc/freeswitch/sip_profiles/nat_gateway"
    }
  ]

  additional_security_group_ids = [module.db.security_group.id, aws_security_group.efs_sip_gateways.id]
}

# -----------------------------------------------------------------------------
# Rating Engine (CGRates)
# Call rating and billing engine.
# -----------------------------------------------------------------------------
module "rating_engine" {
  source = "../modules/ecs_service"

  name           = "rating-engine"
  cluster        = module.ecs_cluster
  region         = module.hydrogen_region
  image          = "${local.ecr_base}/rating-engine:latest"
  container_port = 2080
  cpu            = 512
  memory         = 1024
  desired_count  = 1

  environment = {
    STORDB_DBNAME       = "cgrates"
    STORDB_USER         = "somleng"
    STORDB_HOST         = module.db.this.endpoint
    STORDB_PORT         = "5432"
    DATADB_HOST         = local.redis_endpoint
    DATADB_USER         = ""
    DATADB_PORT         = "6379"
    DATADB_DBNAME       = "2"
    CONNECTION_MODE     = "*localhost"
    LOG_LEVEL           = "7"
    HTTP_LISTEN_ADDRESS = "0.0.0.0:2080"
    BOOTSTRAP_DB        = "true"
    SERVER_MODE         = "api"
    JSON_RPC_USERNAME   = "cgrates"
  }

  secrets = {
    STORDB_PASSWORD    = module.db.master_password_parameter.arn
    JSON_RPC_PASSWORD  = aws_ssm_parameter.rating_engine_password.arn
  }

  additional_security_group_ids = [module.db.security_group.id]
}
