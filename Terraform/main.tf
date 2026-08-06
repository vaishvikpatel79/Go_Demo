locals {
  # Construct full ECR image URIs for every service from the service_tags map.
  # service_tags = { "app-service" = "v1", "product-service" = "v1", ... }
  # Resulting map: { "app-service" = "123456789012.dkr.ecr.us-east-1.amazonaws.com/app-service:v1", ... }
  service_images = {
    for service_name, tag in var.service_tags :
    service_name => "${var.account_id}.dkr.ecr.${var.region}.amazonaws.com/${var.service_repositories[service_name]}:${tag}"
  }
}

resource "aws_vpc" "go_demo_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name      = "${var.project_name}-${var.environment}-vpc"
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = var.managed_by
  }
}

resource "aws_subnet" "public_subnet_1" {
  vpc_id                  = aws_vpc.go_demo_vpc.id
  cidr_block              = var.public_subnet_1_cidr
  availability_zone       = var.public_subnet_1_az
  map_public_ip_on_launch = true

  tags = {
    Name        = "${var.project_name}-${var.environment}-public-subnet-1"
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = var.managed_by
  }
}

resource "aws_subnet" "public_subnet_2" {
  vpc_id                  = aws_vpc.go_demo_vpc.id
  cidr_block              = var.public_subnet_2_cidr
  availability_zone       = var.public_subnet_2_az
  map_public_ip_on_launch = true

  tags = {
    Name        = "${var.project_name}-${var.environment}-public-subnet-2"
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = var.managed_by
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.go_demo_vpc.id

  tags = {
    Name        = "${var.project_name}-${var.environment}-igw"
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = var.managed_by
  }
}

resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.go_demo_vpc.id

  tags = {
    Name        = "${var.project_name}-${var.environment}-public-rt"
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = var.managed_by
  }
}

resource "aws_route" "public_route_default" {
  route_table_id         = aws_route_table.public_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

resource "aws_route_table_association" "public_subnet_1_assoc" {
  subnet_id      = aws_subnet.public_subnet_1.id
  route_table_id = aws_route_table.public_route_table.id
}

resource "aws_route_table_association" "public_subnet_2_assoc" {
  subnet_id      = aws_subnet.public_subnet_2.id
  route_table_id = aws_route_table.public_route_table.id
}

resource "aws_security_group" "alb_sg" {
  name   = "${var.project_name}-${var.environment}-alb-sg"
  vpc_id = aws_vpc.go_demo_vpc.id

  tags = {
    Name        = "${var.project_name}-${var.environment}-alb-sg"
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = var.managed_by
  }
}

resource "aws_security_group" "frontend_service_sg" {
  name   = "${var.project_name}-${var.environment}-frontend-sg"
  vpc_id = aws_vpc.go_demo_vpc.id

  tags = {
    Name        = "${var.project_name}-${var.environment}-frontend-sg"
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = var.managed_by
  }
}

resource "aws_security_group" "backend_service_sg" {
  name   = "${var.project_name}-${var.environment}-backend-sg"
  vpc_id = aws_vpc.go_demo_vpc.id

  tags = {
    Name        = "${var.project_name}-${var.environment}-backend-sg"
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = var.managed_by
  }
}

resource "aws_security_group_rule" "alb_ingress_http" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.alb_sg.id
  description       = "Allow HTTP from anywhere"
}

resource "aws_security_group_rule" "alb_egress_all_to_anywhere" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.alb_sg.id
  description       = "Allow all outbound from ALB"
}

resource "aws_security_group_rule" "frontend_ingress_from_alb" {
  type                     = "ingress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  security_group_id        = aws_security_group.frontend_service_sg.id
  source_security_group_id = aws_security_group.alb_sg.id
  description              = "Allow ALB to reach frontend on 80"
}

resource "aws_security_group_rule" "backend_ingress_from_alb" {
  type                     = "ingress"
  from_port                = 8080
  to_port                  = 8080
  protocol                 = "tcp"
  security_group_id        = aws_security_group.backend_service_sg.id
  source_security_group_id = aws_security_group.alb_sg.id
  description              = "Allow ALB to reach backend on 8080"
}

resource "aws_security_group_rule" "frontend_egress_all" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.frontend_service_sg.id
  description       = "Allow frontend outbound to anywhere"
}

resource "aws_security_group_rule" "backend_egress_all" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.backend_service_sg.id
  description       = "Allow backend outbound to anywhere"
}

resource "aws_iam_role" "ecs_task_execution_role" {
  name = "${var.project_name}-${var.environment}-ecs-task-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name        = "${var.project_name}-${var.environment}-ecs-task-execution-role"
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = var.managed_by
  }
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_attachment" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_cloudwatch_log_group" "frontend_log_group" {
  name = "/ecs/${var.project_name}-${var.environment}-frontend"

  tags = {
    Name        = "${var.project_name}-${var.environment}-frontend-log"
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = var.managed_by
  }
}

resource "aws_cloudwatch_log_group" "backend_log_group" {
  name = "/ecs/${var.project_name}-${var.environment}-backend"

  tags = {
    Name        = "${var.project_name}-${var.environment}-backend-log"
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = var.managed_by
  }
}

resource "aws_ecs_cluster" "ecs_cluster" {
  name = "${var.project_name}-${var.environment}-ecs-cluster"

  tags = {
    Name        = "${var.project_name}-${var.environment}-ecs-cluster"
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = var.managed_by
  }
}

resource "aws_ecs_task_definition" "frontend_task_def" {
  family                   = "${var.project_name}-${var.environment}-frontend"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = tostring(var.frontend_cpu_units)
  memory                   = tostring(var.frontend_memory_mb)
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn

  container_definitions = jsonencode([
    {
      name      = "frontend"
      image     = local.service_images["frontend-service"]
      cpu       = var.frontend_cpu_units
      memory    = var.frontend_memory_mb
      essential = true
      portMappings = [
        {
          containerPort = var.frontend_container_port
          protocol      = "tcp"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.frontend_log_group.name
          awslogs-region        = var.region
          awslogs-stream-prefix = "frontend"
        }
      }
    }
  ])

  tags = {
    Name        = "${var.project_name}-${var.environment}-frontend-task"
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = var.managed_by
  }

  depends_on = [
    aws_iam_role.ecs_task_execution_role,
    aws_cloudwatch_log_group.frontend_log_group,
    aws_ecs_cluster.ecs_cluster
  ]
}

resource "aws_ecs_task_definition" "backend_task_def" {
  family                   = "${var.project_name}-${var.environment}-backend"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = tostring(var.backend_cpu_units)
  memory                   = tostring(var.backend_memory_mb)
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn

  container_definitions = jsonencode([
    {
      name      = "backend"
      image     = local.service_images["backend-service"]
      cpu       = var.backend_cpu_units
      memory    = var.backend_memory_mb
      essential = true
      portMappings = [
        {
          containerPort = var.backend_container_port
          protocol      = "tcp"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.backend_log_group.name
          awslogs-region        = var.region
          awslogs-stream-prefix = "backend"
        }
      }
    }
  ])

  tags = {
    Name        = "${var.project_name}-${var.environment}-backend-task"
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = var.managed_by
  }

  depends_on = [
    aws_iam_role.ecs_task_execution_role,
    aws_cloudwatch_log_group.backend_log_group,
    aws_ecs_cluster.ecs_cluster
  ]
}

resource "aws_lb" "app_lb" {
  name               = "${var.project_name}-${var.environment}-alb"
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [aws_subnet.public_subnet_1.id, aws_subnet.public_subnet_2.id]
  internal           = false

  tags = {
    Name        = "${var.project_name}-${var.environment}-alb"
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = var.managed_by
  }

  depends_on = [
    aws_subnet.public_subnet_1,
    aws_subnet.public_subnet_2,
    aws_security_group.alb_sg
  ]
}

resource "aws_lb_target_group" "frontend_tg" {
  name        = "${var.project_name}-${var.environment}-frontend-tg"
  port        = var.frontend_container_port
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = aws_vpc.go_demo_vpc.id

  health_check {
    path                = "/"
    protocol            = "HTTP"
    interval            = 30
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-frontend-tg"
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = var.managed_by
  }

  depends_on = [aws_lb.app_lb]
}

resource "aws_lb_target_group" "backend_tg" {
  name        = "${var.project_name}-${var.environment}-backend-tg"
  port        = var.backend_container_port
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = aws_vpc.go_demo_vpc.id

  health_check {
    path                = "/health"
    protocol            = "HTTP"
    interval            = 30
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-backend-tg"
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = var.managed_by
  }

  depends_on = [aws_lb.app_lb]
}

resource "aws_lb_listener" "http_listener" {
  load_balancer_arn = aws_lb.app_lb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.frontend_tg.arn
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-http-listener"
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = var.managed_by
  }

  depends_on = [aws_lb.app_lb, aws_lb_target_group.frontend_tg]
}

resource "aws_lb_listener_rule" "api_listener_rule" {
  listener_arn = aws_lb_listener.http_listener.arn
  priority     = 1

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.backend_tg.arn
  }

  condition {
    path_pattern {
      values = ["/api/*"]
    }
  }

  depends_on = [aws_lb_listener.http_listener, aws_lb_target_group.backend_tg]
}

resource "aws_ecs_service" "frontend_service" {
  name            = "${var.project_name}-${var.environment}-frontend-svc"
  cluster         = aws_ecs_cluster.ecs_cluster.id
  task_definition = aws_ecs_task_definition.frontend_task_def.arn
  desired_count   = var.frontend_desired_count
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = [aws_subnet.public_subnet_1.id, aws_subnet.public_subnet_2.id]
    security_groups = [aws_security_group.frontend_service_sg.id]
    assign_public_ip = "ENABLED"
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.frontend_tg.arn
    container_name   = "frontend"
    container_port   = var.frontend_container_port
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-frontend-svc"
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = var.managed_by
  }

  depends_on = [
    aws_ecs_cluster.ecs_cluster,
    aws_ecs_task_definition.frontend_task_def,
    aws_lb_target_group.frontend_tg,
    aws_security_group.frontend_service_sg,
    aws_subnet.public_subnet_1,
    aws_subnet.public_subnet_2
  ]
}

resource "aws_ecs_service" "backend_service" {
  name            = "${var.project_name}-${var.environment}-backend-svc"
  cluster         = aws_ecs_cluster.ecs_cluster.id
  task_definition = aws_ecs_task_definition.backend_task_def.arn
  desired_count   = var.backend_desired_count
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = [aws_subnet.public_subnet_1.id, aws_subnet.public_subnet_2.id]
    security_groups = [aws_security_group.backend_service_sg.id]
    assign_public_ip = "ENABLED"
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.backend_tg.arn
    container_name   = "backend"
    container_port   = var.backend_container_port
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-backend-svc"
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = var.managed_by
  }

  depends_on = [
    aws_ecs_cluster.ecs_cluster,
    aws_ecs_task_definition.backend_task_def,
    aws_lb_target_group.backend_tg,
    aws_security_group.backend_service_sg,
    aws_subnet.public_subnet_1,
    aws_subnet.public_subnet_2
  ]
}
