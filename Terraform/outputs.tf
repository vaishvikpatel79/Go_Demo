output "alb_dns_name" {
  description = "Public DNS name of the Application Load Balancer"
  value       = aws_lb.application_load_balancer.dns_name
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

output "frontend_ecr_image_uri" {
  description = "Full ECR image URI (including tag) for the frontend image as constructed from var.service_tags"
  value       = local.service_images["go-demo-frontend-service"]
}

output "backend_ecr_image_uri" {
  description = "Full ECR image URI (including tag) for the backend image as constructed from var.service_tags"
  value       = local.service_images["go-demo-backend-service"]
}

output "frontend_ecr_repository_uri" {
  description = "ECR repository URI for the frontend image (without tag)"
  value       = split(":", local.service_images["go-demo-frontend-service"])[0]
}

output "backend_ecr_repository_uri" {
  description = "ECR repository URI for the backend image (without tag)"
  value       = split(":", local.service_images["go-demo-backend-service"])[0]
}

output "frontend_target_group_arn" {
  description = "ARN of the Frontend Target Group"
  value       = aws_lb_target_group.tg_frontend.arn
}

output "backend_target_group_arn" {
  description = "ARN of the Backend Target Group"
  value       = aws_lb_target_group.tg_backend.arn
}

output "application_url" {
  description = "Public URL of the deployed application (http://<ALB-DNS>)"
  value       = "http://${aws_lb.application_load_balancer.dns_name}"
}

output "deployment_contract" {
  value = {
    meta = {
      contract_version = "1"
      cloud            = "aws"
      runtime          = "ecs_fargate"
      application_type = "fullstack"
      environment      = var.environment
      region           = var.region
      deployment_type  = "managed"
    }

    compute = {
      cluster_name = aws_ecs_cluster.go_demo_ecs_cluster.name
      service_name = null
      service_names = {
        "go-demo-frontend-service" = aws_ecs_service.frontend_ecs_service.name
        "go-demo-backend-service"  = aws_ecs_service.backend_ecs_service.name
      }
      task_family   = null
      workload_name = null
    }

    network = {
      vpc_id             = aws_vpc.go_demo_vpc.id
      subnet_ids         = [aws_subnet.public_subnet_1.id, aws_subnet.public_subnet_2.id]
      security_group_ids = [aws_security_group.sg_alb.id, aws_security_group.sg_frontend_service.id, aws_security_group.sg_backend_service.id]
      ingress_id         = aws_lb.application_load_balancer.arn
    }

    routing = {
      public_endpoint      = "http://${aws_lb.application_load_balancer.dns_name}"
      internal_endpoint    = null
      custom_domain        = null
      certificate_required = false
      certificate_mode     = null
    }

    data = {
      database_endpoint = null
      cache_endpoint    = null
      object_store_name = null
    }

    security = {
      certificate_ref = null
      secret_refs     = null
      role_arns = {
        ecs_task_execution_role = aws_iam_role.ecs_task_execution_role.arn
      }
    }

    health = {
      frontend_path  = "/"
      backend_path   = "/health"
      readiness_path = null
      liveness_path  = null
    }
  }
}
