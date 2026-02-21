variable "aws_default_region" {
  default = "ap-southeast-1"
}

variable "aws_helium_region" {
  default = "us-east-1"
}

variable "redis_endpoint" {
  description = "Redis / ElastiCache endpoint (without port)"
  type        = string
}
