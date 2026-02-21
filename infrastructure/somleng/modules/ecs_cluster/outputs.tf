output "cluster" {
  value = aws_ecs_cluster.this
}

output "service_discovery_namespace" {
  value = aws_service_discovery_private_dns_namespace.this
}

output "task_execution_role" {
  value = aws_iam_role.ecs_task_execution
}

output "task_role" {
  value = aws_iam_role.ecs_task
}
