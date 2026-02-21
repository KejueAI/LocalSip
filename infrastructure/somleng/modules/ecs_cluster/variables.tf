variable "name" {
  description = "Name of the ECS cluster"
  type        = string
}

variable "region" {
  description = "Region module output"
}

variable "service_discovery_namespace" {
  description = "Private DNS namespace for service discovery (e.g. somleng.internal)"
  type        = string
  default     = "somleng.internal"
}
