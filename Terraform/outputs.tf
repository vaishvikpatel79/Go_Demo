output "alb_dns_name" {
  description = "Application Load Balancer DNS name"
  value       = aws_lb.app_load_balancer.dns_name
}

output "ecs_cluster_name" {
  description = "ECS cluster name"
  value       = aws_ecs_cluster.fastapi_demo_cluster.name
}

output "ecs_service_name" {
  description = "ECS service name"
  value       = aws_ecs_service.fastapi_demo_service.name
}

output "ecs_task_definition_arn" {
  description = "ECS task definition ARN"
  value       = aws_ecs_task_definition.fastapi_demo_task_definition.arn
}

output "ecr_image_uri" {
  description = "Constructed ECR image URI for the service"
  value       = local.service_images["fastapi-demo-service"]
}

output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.fastapi_demo_vpc.id
}

output "public_subnet_ids" {
  description = "Public subnet IDs"
  value       = [aws_subnet.public_subnet_1.id, aws_subnet.public_subnet_2.id]
}

output "security_group_ids" {
  description = "Security group IDs (ALB and ECS)"
  value = {
    alb_sg = aws_security_group.alb_sg.id
    ecs_sg = aws_security_group.ecs_service_sg.id
  }
}

output "target_group_arn" {
  description = "ALB target group ARN"
  value       = aws_lb_target_group.fastapi_demo_tg.arn
}

output "deployment_contract" {
  description = "Canonical deployment contract for the deployment agent"
  value = {
    meta = {
      contract_version = "1.0"
      cloud            = "aws"
      runtime          = "ecs"
      application_type = "backend"
      environment      = var.environment
      region           = var.region
      deployment_type  = "fargate"
    }

    compute = {
      cluster_name = aws_ecs_cluster.fastapi_demo_cluster.name
      service_name = aws_ecs_service.fastapi_demo_service.name
      service_names = {
        ("fastapi-demo-service") = aws_ecs_service.fastapi_demo_service.name
      }
      task_family   = aws_ecs_task_definition.fastapi_demo_task_definition.family
      workload_name = aws_ecs_service.fastapi_demo_service.name
    }

    network = {
      vpc_id             = aws_vpc.fastapi_demo_vpc.id
      subnet_ids         = [aws_subnet.public_subnet_1.id, aws_subnet.public_subnet_2.id]
      security_group_ids = [aws_security_group.alb_sg.id, aws_security_group.ecs_service_sg.id]
      ingress_id         = aws_lb.app_load_balancer.arn
    }

    routing = {
      public_endpoint      = aws_lb.app_load_balancer.dns_name
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
      frontend_path  = null
      backend_path   = var.health_check_path
      readiness_path = var.health_check_path
      liveness_path  = var.health_check_path
    }
  }
}
