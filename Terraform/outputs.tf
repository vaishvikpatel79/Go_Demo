output "alb_dns_name" {
  description = "Public DNS name of the Application Load Balancer"
  value       = aws_lb.go_demo_alb.dns_name
}

output "ecs_cluster_name" {
  description = "Name of the ECS Cluster"
  value       = aws_ecs_cluster.go_demo_ecs_cluster.name
}

output "frontend_ecs_service_name" {
  description = "Name of the Frontend ECS Service"
  value       = aws_ecs_service.frontend_ecs_service.name
}

output "backend_ecs_service_name" {
  description = "Name of the Backend ECS Service"
  value       = aws_ecs_service.backend_ecs_service.name
}

output "frontend_task_definition_arn" {
  description = "ARN of the Frontend Task Definition"
  value       = aws_ecs_task_definition.frontend_task_definition.arn
}

output "backend_task_definition_arn" {
  description = "ARN of the Backend Task Definition"
  value       = aws_ecs_task_definition.backend_task_definition.arn
}

output "frontend_ecr_repository_uri" {
  description = "Amazon ECR Repository URI for the Frontend image (constructed URI)"
  value       = local.service_images["frontend-service"]
}

output "backend_ecr_repository_uri" {
  description = "Amazon ECR Repository URI for the Backend image (constructed URI)"
  value       = local.service_images["backend-service"]
}

output "frontend_target_group_arn" {
  description = "ARN of the Frontend Target Group"
  value       = aws_lb_target_group.go_demo_frontend_tg.arn
}

output "backend_target_group_arn" {
  description = "ARN of the Backend Target Group"
  value       = aws_lb_target_group.go_demo_backend_tg.arn
}

output "application_url" {
  description = "Public URL of the deployed application (`http://<ALB-DNS>`)"
  value       = "http://${aws_lb.go_demo_alb.dns_name}"
}

output "deployment_contract" {
  value = {
    meta = {
      contract_version = "1.0"
      cloud = "aws"
      runtime = "ecs_fargate"
      application_type = "Fullstack app"
      environment = var.environment
      region = var.region
      deployment_type = "container"
    }

    compute = {
      cluster_name = aws_ecs_cluster.go_demo_ecs_cluster.name
      service_name = null
      service_names = {
        "frontend-service" = aws_ecs_service.frontend_ecs_service.name
        "backend-service"  = aws_ecs_service.backend_ecs_service.name
      }
      task_family = null
      workload_name = null
    }

    network = {
      vpc_id = aws_vpc.go_demo_vpc.id
      subnet_ids = [aws_subnet.public_subnet_1.id, aws_subnet.public_subnet_2.id]
      security_group_ids = [aws_security_group.alb_sg.id, aws_security_group.frontend_service_sg.id, aws_security_group.backend_service_sg.id]
      ingress_id = aws_lb.go_demo_alb.arn
    }

    routing = {
      public_endpoint = "http://${aws_lb.go_demo_alb.dns_name}"
      internal_endpoint = null
      custom_domain = null
      certificate_required = false
      certificate_mode = null
    }

    data = {
      database_endpoint = null
      cache_endpoint = null
      object_store_name = null
    }

    security = {
      certificate_ref = null
      secret_refs = null
      role_arns = {
        ecs_task_execution_role = aws_iam_role.ecs_task_execution_role.arn
      }
    }

    health = {
      frontend_path = "/"
      backend_path = "/api/health"
      readiness_path = "/health"
      liveness_path = "/health"
    }
  }
}
