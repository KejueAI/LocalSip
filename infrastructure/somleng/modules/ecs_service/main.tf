data "aws_region" "this" {}

locals {
  subnets = var.use_public_subnets ? var.region.vpc.public_subnets : var.region.vpc.private_subnets

  # Build port mappings: always include container_port (TCP), plus any UDP ports
  tcp_port_mappings = [
    {
      containerPort = var.container_port
      hostPort      = var.container_port
      protocol      = "tcp"
    }
  ]

  udp_port_mappings = [
    for port in var.udp_ports : {
      containerPort = port
      hostPort      = port
      protocol      = "udp"
    }
  ]

  port_mappings = concat(local.tcp_port_mappings, local.udp_port_mappings)

  environment = [
    for k, v in var.environment : {
      name  = k
      value = v
    }
  ]

  secrets = [
    for k, v in var.secrets : {
      name      = k
      valueFrom = v
    }
  ]
}

# CloudWatch log group
resource "aws_cloudwatch_log_group" "this" {
  name              = "/ecs/${var.name}"
  retention_in_days = 30
}

# Task definition
resource "aws_ecs_task_definition" "this" {
  family                   = var.name
  requires_compatibilities = ["FARGATE"]
  network_mode             = var.network_mode
  cpu                      = var.cpu
  memory                   = var.memory
  execution_role_arn       = var.cluster.task_execution_role.arn
  task_role_arn            = var.cluster.task_role.arn

  container_definitions = jsonencode([
    merge(
      {
        name         = var.name
        image        = var.image
        essential    = true
        portMappings = local.port_mappings
        environment  = local.environment
        secrets      = local.secrets
        logConfiguration = {
          logDriver = "awslogs"
          options = {
            "awslogs-group"         = aws_cloudwatch_log_group.this.name
            "awslogs-region"        = data.aws_region.this.name
            "awslogs-stream-prefix" = var.name
          }
        }
      },
      var.command != null ? { command = var.command } : {},
      length(var.mount_points) > 0 ? { mountPoints = var.mount_points } : {}
    )
  ])

  dynamic "volume" {
    for_each = var.volumes
    content {
      name = volume.value.name

      dynamic "efs_volume_configuration" {
        for_each = volume.value.efs_volume_configuration != null ? [volume.value.efs_volume_configuration] : []
        content {
          file_system_id = efs_volume_configuration.value.file_system_id
          root_directory = efs_volume_configuration.value.root_directory
        }
      }
    }
  }
}

# Security group for the service
resource "aws_security_group" "this" {
  name   = "${var.name}-ecs"
  vpc_id = var.region.vpc.vpc_id

  # Allow inbound on container port from within VPC
  ingress {
    from_port   = var.container_port
    to_port     = var.container_port
    protocol    = "tcp"
    cidr_blocks = [var.region.vpc.vpc_cidr_block]
  }

  # Allow UDP inbound if SIP/RTP ports are specified
  dynamic "ingress" {
    for_each = var.udp_ports
    content {
      from_port   = ingress.value
      to_port     = ingress.value
      protocol    = "udp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.name}-ecs"
  }
}

# Service discovery registration
resource "aws_service_discovery_service" "this" {
  count = var.enable_service_discovery ? 1 : 0
  name  = var.name

  dns_config {
    namespace_id = var.cluster.service_discovery_namespace.id

    dns_records {
      ttl  = 10
      type = "A"
    }

    routing_policy = "MULTIVALUE"
  }

  health_check_custom_config {
    failure_threshold = 1
  }
}

# ALB target group (only if load balancer is attached)
resource "aws_lb_target_group" "this" {
  count       = var.load_balancer != null ? 1 : 0
  name        = var.name
  port        = var.container_port
  protocol    = "HTTP"
  vpc_id      = var.region.vpc.vpc_id
  target_type = "ip"

  health_check {
    path                = var.health_check_path
    healthy_threshold   = 3
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
    matcher             = "200"
  }

  deregistration_delay = 30
}

# ALB listener rule
resource "aws_lb_listener_rule" "this" {
  count        = var.load_balancer != null && var.host_header != null ? 1 : 0
  listener_arn = var.load_balancer.https_listener.arn
  priority     = var.listener_priority

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this[0].arn
  }

  condition {
    host_header {
      values = var.host_header
    }
  }
}

# ECS service
resource "aws_ecs_service" "this" {
  name            = var.name
  cluster         = var.cluster.cluster.id
  task_definition = aws_ecs_task_definition.this.arn
  desired_count   = var.desired_count

  capacity_provider_strategy {
    capacity_provider = "FARGATE"
    weight            = 1
    base              = 1
  }

  network_configuration {
    subnets          = local.subnets
    security_groups  = concat([aws_security_group.this.id], var.additional_security_group_ids)
    assign_public_ip = var.assign_public_ip
  }

  dynamic "load_balancer" {
    for_each = var.load_balancer != null ? [1] : []
    content {
      target_group_arn = aws_lb_target_group.this[0].arn
      container_name   = var.name
      container_port   = var.container_port
    }
  }

  dynamic "service_registries" {
    for_each = var.enable_service_discovery ? [1] : []
    content {
      registry_arn = aws_service_discovery_service.this[0].arn
    }
  }

  lifecycle {
    ignore_changes = [task_definition, desired_count]
  }
}
