output "vpc_id" {
  description = "ID of the created VPC"
  value       = aws_vpc.go_demo_vpc.id
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = [aws_subnet.public_subnet_1.id, aws_subnet.public_subnet_2.id]
}

output "alb_dns_name" {
  description = "Public DNS name of the Application Load Balancer"
  value       = aws_lb.application_lb.dns_name
}

output "alb_arn" {
  description = "ARN of the Application Load Balancer"
  value       = aws_lb.application_lb.arn
}

output "frontend_target_group_arn" {
  description = "ARN of the frontend target group"
  value       = aws_lb_target_group.frontend_tg.arn
}

output "backend_target_group_arn" {
  description = "ARN of the backend target group"
  value       = aws_lb_target_group.backend_tg.arn
}

output "ecs_cluster_name" {
  description = "ECS cluster name"
  value       = aws_ecs_cluster.go_demo_cluster.name
}

output "frontend_service_name" {
  description = "Frontend ECS service name"
  value       = aws_ecs_service.frontend_service.name
}

output "backend_service_name" {
  description = "Backend ECS service name"
  value       = aws_ecs_service.backend_service.name
}

output "ecs_task_execution_role_arn" {
  description = "ARN of the ECS task execution role"
  value       = aws_iam_role.ecs_task_execution_role.arn
}

output "frontend_task_definition_arn" {
  description = "ARN of the frontend task definition"
  value       = aws_ecs_task_definition.frontend_task_definition.arn
}

output "backend_task_definition_arn" {
  description = "ARN of the backend task definition"
  value       = aws_ecs_task_definition.backend_task_definition.arn
}

output "frontend_log_group_name" {
  description = "CloudWatch log group for frontend"
  value       = aws_cloudwatch_log_group.frontend_log_group.name
}

output "backend_log_group_name" {
  description = "CloudWatch log group for backend"
  value       = aws_cloudwatch_log_group.backend_log_group.name
}

output "deployment_contract" {
  description = "Canonical deployment contract for the deployment agent"
  value = {
    meta = {
      contract_version = "1.0"
      cloud            = "aws"
      runtime          = "ecs_fargate"
      application_type = "fullstack"
      environment      = var.environment
      region           = var.region
      deployment_type  = "container"
    }

    compute = {
      cluster_name  = aws_ecs_cluster.go_demo_cluster.name
      service_name  = null
      service_names = {
        "frontend-service" = aws_ecs_service.frontend_service.name
        "backend-service"  = aws_ecs_service.backend_service.name
      }
      task_family    = null
      workload_name  = null
    }

    network = {
      vpc_id             = aws_vpc.go_demo_vpc.id
      subnet_ids         = [aws_subnet.public_subnet_1.id, aws_subnet.public_subnet_2.id]
      security_group_ids = [aws_security_group.alb_sg.id, aws_security_group.frontend_service_sg.id, aws_security_group.backend_service_sg.id]
      ingress_id         = aws_lb.application_lb.arn
    }

    routing = {
      public_endpoint        = aws_lb.application_lb.dns_name
      internal_endpoint      = null
      custom_domain          = null
      certificate_required   = false
      certificate_mode       = null
    }

    data = {
      database_endpoint   = null
      cache_endpoint      = null
      object_store_name   = null
    }

    security = {
      certificate_ref = null
      secret_refs     = null
      role_arns = {
        ecs_task_execution_role = aws_iam_role.ecs_task_execution_role.arn
      }
    }

    health = {
      frontend_path   = "/"
      backend_path    = "/health"
      readiness_path  = null
      liveness_path   = null
    }
  }
}
