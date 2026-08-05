output "alb_dns_name" {
  description = "Public DNS name of the Application Load Balancer"
  value       = aws_lb.go-demo-alb.dns_name
}

output "ecs_cluster_name" {
  description = "Name of the ECS Cluster"
  value       = aws_ecs_cluster.go-demo-cluster.name
}

output "frontend_ecs_service_name" {
  description = "Name of the Frontend ECS Service"
  value       = aws_ecs_service.frontend-service.name
}

output "backend_ecs_service_name" {
  description = "Name of the Backend ECS Service"
  value       = aws_ecs_service.backend-service.name
}

output "frontend_task_definition_arn" {
  description = "ARN of the Frontend Task Definition"
  value       = aws_ecs_task_definition.frontend-task-def.arn
}

output "backend_task_definition_arn" {
  description = "ARN of the Backend Task Definition"
  value       = aws_ecs_task_definition.backend-task-def.arn
}

output "frontend_ecr_repository_uri" {
  description = "Amazon ECR Repository URI for the Frontend image"
  value       = "${var.account_id}.dkr.ecr.${var.region}.amazonaws.com/${var.service_repositories["frontend-service"]}"
}

output "backend_ecr_repository_uri" {
  description = "Amazon ECR Repository URI for the Backend image"
  value       = "${var.account_id}.dkr.ecr.${var.region}.amazonaws.com/${var.service_repositories["backend-service"]}"
}

output "frontend_target_group_arn" {
  description = "ARN of the Frontend Target Group"
  value       = aws_lb_target_group.go-demo-frontend-tg.arn
}

output "backend_target_group_arn" {
  description = "ARN of the Backend Target Group"
  value       = aws_lb_target_group.go-demo-backend-tg.arn
}

output "application_url" {
  description = "Public URL of the deployed application"
  value       = "http://${aws_lb.go-demo-alb.dns_name}"
}

output "deployment_contract" {
  description = "Canonical deployment contract for downstream agents"
  value = {
    meta = {
      contract_version = "1.0"
      cloud            = "aws"
      runtime          = "ecs_fargate"
      application_type = "fullstack"
      environment      = var.environment
      region           = var.region
      deployment_type  = "public"
    }

    compute = {
      cluster_name = aws_ecs_cluster.go-demo-cluster.name
      service_name = null
      service_names = {
        "frontend-service" = aws_ecs_service.frontend-service.name
        "backend-service"  = aws_ecs_service.backend-service.name
      }
      task_family  = null
      workload_name = null
    }

    network = {
      vpc_id             = aws_vpc.go-demo-vpc.id
      subnet_ids         = [aws_subnet.public-subnet-1.id, aws_subnet.public-subnet-2.id]
      security_group_ids = [aws_security_group.alb-sg.id, aws_security_group.frontend-service-sg.id, aws_security_group.backend-service-sg.id]
      ingress_id         = aws_lb.go-demo-alb.arn
    }

    routing = {
      public_endpoint       = "http://${aws_lb.go-demo-alb.dns_name}"
      internal_endpoint     = null
      custom_domain         = null
      certificate_required  = false
      certificate_mode      = null
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
        ecs_task_execution_role = aws_iam_role.ecs-task-execution-role.arn
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
