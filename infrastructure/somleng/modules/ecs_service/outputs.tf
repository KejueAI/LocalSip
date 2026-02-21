output "service" {
  value = aws_ecs_service.this
}

output "task_definition" {
  value = aws_ecs_task_definition.this
}

output "security_group" {
  value = aws_security_group.this
}

output "target_group" {
  value = var.load_balancer != null ? aws_lb_target_group.this[0] : null
}

output "service_discovery" {
  value = var.enable_service_discovery ? aws_service_discovery_service.this[0] : null
}

output "log_group" {
  value = aws_cloudwatch_log_group.this
}
