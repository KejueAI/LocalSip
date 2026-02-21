variable "name" {
  description = "Service name (e.g. somleng-api, somleng-switch, freeswitch)"
  type        = string
}

variable "cluster" {
  description = "ECS cluster module output"
}

variable "region" {
  description = "Region module output"
}

variable "image" {
  description = "Docker image URI (e.g. <account>.dkr.ecr.<region>.amazonaws.com/somleng:latest)"
  type        = string
}

variable "container_port" {
  description = "Port the container listens on"
  type        = number
  default     = 3000
}

variable "cpu" {
  description = "CPU units for the task (1024 = 1 vCPU)"
  type        = number
  default     = 512
}

variable "memory" {
  description = "Memory in MiB for the task"
  type        = number
  default     = 1024
}

variable "desired_count" {
  description = "Number of tasks to run"
  type        = number
  default     = 1
}

variable "environment" {
  description = "Environment variables for the container"
  type        = map(string)
  default     = {}
}

variable "secrets" {
  description = "Secrets from SSM Parameter Store. Map of env var name to SSM parameter ARN."
  type        = map(string)
  default     = {}
}

variable "command" {
  description = "Override container command"
  type        = list(string)
  default     = null
}

variable "health_check_path" {
  description = "Health check path for the target group"
  type        = string
  default     = "/health_checks"
}

variable "load_balancer" {
  description = "Load balancer module output. Set to null for services without a load balancer."
  default     = null
}

variable "listener_priority" {
  description = "Priority for the ALB listener rule"
  type        = number
  default     = null
}

variable "host_header" {
  description = "Host header for ALB routing (e.g. api.somleng.org)"
  type        = list(string)
  default     = null
}

variable "enable_service_discovery" {
  description = "Register this service in Cloud Map for DNS-based discovery"
  type        = bool
  default     = true
}

variable "protocol" {
  description = "Network protocol: tcp or udp"
  type        = string
  default     = "tcp"
}

variable "network_mode" {
  description = "Docker network mode: awsvpc or host"
  type        = string
  default     = "awsvpc"
}

variable "assign_public_ip" {
  description = "Assign public IP to tasks (needed for public subnets without NAT)"
  type        = bool
  default     = false
}

variable "use_public_subnets" {
  description = "Deploy tasks in public subnets (for FreeSWITCH SIP/RTP)"
  type        = bool
  default     = false
}

variable "additional_security_group_ids" {
  description = "Additional security group IDs to attach to the service"
  type        = list(string)
  default     = []
}

variable "volumes" {
  description = "EFS or bind mount volumes"
  type = list(object({
    name = string
    efs_volume_configuration = optional(object({
      file_system_id = string
      root_directory = optional(string, "/")
    }))
  }))
  default = []
}

variable "mount_points" {
  description = "Container mount points"
  type = list(object({
    sourceVolume  = string
    containerPath = string
    readOnly      = optional(bool, false)
  }))
  default = []
}

variable "udp_ports" {
  description = "UDP ports to expose (for FreeSWITCH SIP/RTP)"
  type        = list(number)
  default     = []
}
