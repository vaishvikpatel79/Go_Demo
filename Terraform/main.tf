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
  cidr_block = var.vpc_cidr

  enable_dns_support   = var.enable_dns_support
  enable_dns_hostnames = var.enable_dns_hostnames

  tags = {
    Name        = "${var.project_name}-${var.environment}-vpc"
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "Terraform"
  }
}

resource "aws_subnet" "public_subnet_1" {
  vpc_id                  = aws_vpc.go_demo_vpc.id
  cidr_block              = var.subnet1_cidr
  availability_zone       = var.az1
  map_public_ip_on_launch = true

  tags = {
    Name        = "${var.project_name}-${var.environment}-public-subnet-1"
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "Terraform"
  }
}

resource "aws_subnet" "public_subnet_2" {
  vpc_id                  = aws_vpc.go_demo_vpc.id
  cidr_block              = var.subnet2_cidr
  availability_zone       = var.az2
  map_public_ip_on_launch = true

  tags = {
    Name        = "${var.project_name}-${var.environment}-public-subnet-2"
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "Terraform"
  }
}

resource "aws_internet_gateway" "go_demo_igw" {
  vpc_id = aws_vpc.go_demo_vpc.id

  tags = {
    Name        = "${var.project_name}-${var.environment}-igw"
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "Terraform"
  }
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.go_demo_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.go_demo_igw.id
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-public-rt"
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "Terraform"
  }
}

resource "aws_route_table_association" "public_rt_assoc_1" {
  subnet_id      = aws_subnet.public_subnet_1.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "public_rt_assoc_2" {
  subnet_id      = aws_subnet.public_subnet_2.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_security_group" "alb_sg" {
  name   = "${var.project_name}-${var.environment}-alb-sg"
  vpc_id = aws_vpc.go_demo_vpc.id

  tags = {
    Name        = "${var.project_name}-${var.environment}-alb-sg"
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "Terraform"
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

resource "aws_security_group" "frontend_service_sg" {
  name   = "${var.project_name}-${var.environment}-frontend-service-sg"
  vpc_id = aws_vpc.go_demo_vpc.id

  tags = {
    Name        = "${var.project_name}-${var.environment}-frontend-service-sg"
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "Terraform"
  }
}

resource "aws_security_group_rule" "frontend_ingress_from_alb" {
  type                     = "ingress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  security_group_id        = aws_security_group.frontend_service_sg.id
  description              = "Allow ALB to reach frontend on port 80"
  source_security_group_id = aws_security_group.alb_sg.id
  depends_on               = [aws_security_group.frontend_service_sg, aws_security_group.alb_sg]
}

resource "aws_security_group_rule" "frontend_egress_all" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.frontend_service_sg.id
  description       = "Allow all outbound from frontend"
}

resource "aws_security_group" "backend_service_sg" {
  name   = "${var.project_name}-${var.environment}-backend-service-sg"
  vpc_id = aws_vpc.go_demo_vpc.id

  tags = {
    Name        = "${var.project_name}-${var.environment}-backend-service-sg"
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "Terraform"
  }
}

resource "aws_security_group_rule" "backend_ingress_from_alb" {
  type                     = "ingress"
  from_port                = 8080
  to_port                  = 8080
  protocol                 = "tcp"
  security_group_id        = aws_security_group.backend_service_sg.id
  description              = "Allow ALB to reach backend on port 8080"
  source_security_group_id = aws_security_group.alb_sg.id
  depends_on               = [aws_security_group.backend_service_sg, aws_security_group.alb_sg]
}

resource "aws_security_group_rule" "backend_egress_all" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.backend_service_sg.id
  description       = "Allow all outbound from backend"
}

resource "aws_security_group_rule" "alb_egress_to_frontend_sg" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = [aws_vpc.go_demo_vpc.cidr_block]
  security_group_id = aws_security_group.alb_sg.id
  description       = "Allow ALB outbound to VPC (frontend/backends reachable)"
}

resource "aws_security_group_rule" "alb_egress_to_backend_sg" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = [aws_vpc.go_demo_vpc.cidr_block]
  security_group_id = aws_security_group.alb_sg.id
  description       = "Allow ALB outbound to VPC (frontend/backends reachable)"
}

resource "aws_iam_role" "ecs_task_execution_role" {
  name = "${var.project_name}-${var.environment}-ecs-task-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
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
    ManagedBy   = "Terraform"
  }
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_attach" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
  depends_on = [aws_iam_role.ecs_task_execution_role]
}

resource "aws_cloudwatch_log_group" "frontend_logs" {
  name = "/ecs/${var.project_name}-${var.environment}-frontend"

  tags = {
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "Terraform"
  }
}

resource "aws_cloudwatch_log_group" "backend_logs" {
  name = "/ecs/${var.project_name}-${var.environment}-backend"

  tags = {
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "Terraform"
  }
}

resource "aws_ecs_cluster" "go_demo_cluster" {
  name = "${var.project_name}-${var.environment}-cluster"

  tags = {
    Name        = "${var.project_name}-${var.environment}-cluster"
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "Terraform"
  }
}

resource "aws_lb" "app_lb" {
  name               = "${var.project_name}-${var.environment}-alb"
  load_balancer_type = "application"

  subnet_mapping {
    subnet_id = aws_subnet.public_subnet_1.id
  }

  subnet_mapping {
    subnet_id = aws_subnet.public_subnet_2.id
  }

  security_groups = [aws_security_group.alb_sg.id]

  tags = {
    Name        = "${var.project_name}-${var.environment}-alb"
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "Terraform"
  }
}

resource "aws_lb_target_group" "frontend_tg" {
  name        = "${var.project_name}-${var.environment}-frontend-tg"
  target_type = "ip"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.go_demo_vpc.id

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 3
    interval            = 30
    port                = "traffic-port"
    protocol            = "HTTP"
    path                = "/"
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-frontend-tg"
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "Terraform"
  }
}

resource "aws_lb_target_group" "backend_tg" {
  name        = "${var.project_name}-${var.environment}-backend-tg"
  target_type = "ip"
  port        = 8080
  protocol    = "HTTP"
  vpc_id      = aws_vpc.go_demo_vpc.id

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 3
    interval            = 30
    port                = "traffic-port"
    protocol            = "HTTP"
    path                = "/health"
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-backend-tg"
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "Terraform"
  }
}

resource "aws_lb_listener" "http_listener" {
  load_balancer_arn = aws_lb.app_lb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.frontend_tg.arn
  }
}

resource "aws_lb_listener_rule" "backend_listener_rule" {
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
}

resource "aws_ecs_task_definition" "frontend_task" {
  family                   = "${var.project_name}-${var.environment}-frontend"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.frontend_cpu
  memory                   = var.frontend_memory
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn

  container_definitions = jsonencode([
    {
      name      = "frontend"
      image     = local.service_images["go-demo-frontend-service"]
      cpu       = 256
      memory    = 512
      essential = true
      portMappings = [
        {
          containerPort = 80
          hostPort      = 80
          protocol      = "tcp"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.frontend_logs.name
          "awslogs-region"        = var.region
          "awslogs-stream-prefix" = "frontend"
        }
      }
    }
  ])

  tags = {
    Name        = "${var.project_name}-${var.environment}-frontend-task"
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "Terraform"
  }

  depends_on = [aws_iam_role.ecs_task_execution_role, aws_cloudwatch_log_group.frontend_logs]
}

resource "aws_ecs_task_definition" "backend_task" {
  family                   = "${var.project_name}-${var.environment}-backend"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.backend_cpu
  memory                   = var.backend_memory
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn

  container_definitions = jsonencode([
    {
      name      = "backend"
      image     = local.service_images["go-demo-backend-service"]
      cpu       = 256
      memory    = 512
      essential = true
      portMappings = [
        {
          containerPort = 8080
          hostPort      = 8080
          protocol      = "tcp"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.backend_logs.name
          "awslogs-region"        = var.region
          "awslogs-stream-prefix" = "backend"
        }
      }
    }
  ])

  tags = {
    Name        = "${var.project_name}-${var.environment}-backend-task"
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "Terraform"
  }

  depends_on = [aws_iam_role.ecs_task_execution_role, aws_cloudwatch_log_group.backend_logs]
}

resource "aws_ecs_service" "frontend_service" {
  name            = "${var.project_name}-${var.environment}-frontend-service"
  cluster         = aws_ecs_cluster.go_demo_cluster.id
  task_definition = aws_ecs_task_definition.frontend_task.arn
  desired_count   = var.frontend_desired_count

  load_balancer {
    target_group_arn = aws_lb_target_group.frontend_tg.arn
    container_name   = "frontend"
    container_port   = 80
  }

  network_configuration {
    subnets          = [aws_subnet.public_subnet_1.id, aws_subnet.public_subnet_2.id]
    security_groups  = [aws_security_group.frontend_service_sg.id]
    assign_public_ip = true
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-frontend-service"
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "Terraform"
  }

  depends_on = [aws_ecs_cluster.go_demo_cluster, aws_ecs_task_definition.frontend_task, aws_lb_target_group.frontend_tg, aws_lb.app_lb, aws_subnet.public_subnet_1, aws_subnet.public_subnet_2, aws_security_group.frontend_service_sg]
}

resource "aws_ecs_service" "backend_service" {
  name            = "${var.project_name}-${var.environment}-backend-service"
  cluster         = aws_ecs_cluster.go_demo_cluster.id
  task_definition = aws_ecs_task_definition.backend_task.arn
  desired_count   = var.backend_desired_count

  load_balancer {
    target_group_arn = aws_lb_target_group.backend_tg.arn
    container_name   = "backend"
    container_port   = 8080
  }

  network_configuration {
    subnets          = [aws_subnet.public_subnet_1.id, aws_subnet.public_subnet_2.id]
    security_groups  = [aws_security_group.backend_service_sg.id]
    assign_public_ip = true
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-backend-service"
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "Terraform"
  }

  depends_on = [aws_ecs_cluster.go_demo_cluster, aws_ecs_task_definition.backend_task, aws_lb_target_group.backend_tg, aws_lb.app_lb, aws_subnet.public_subnet_1, aws_subnet.public_subnet_2, aws_security_group.backend_service_sg]
}
