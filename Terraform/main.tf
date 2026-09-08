locals {
  # Construct full ECR image URIs for every service from the service_tags map.
  # service_tags = { "app-service" = "v1", "product-service" = "v1", ... }
  # Resulting map: { "app-service" = "123456789012.dkr.ecr.us-east-1.amazonaws.com/app-service:v1", ... }
  service_images = {
    for service_name, tag in var.service_tags :
    service_name => "${var.account_id}.dkr.ecr.${var.region}.amazonaws.com/${var.service_repositories[service_name]}:${tag}"
  }
}

# VPC
resource "aws_vpc" "go_demo_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name       = "${var.project_name}-${var.environment}-vpc"
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "terraform"
  }
}

# Public Subnets
resource "aws_subnet" "public_subnet_1" {
  vpc_id                  = aws_vpc.go_demo_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name       = "${var.project_name}-${var.environment}-public-1"
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "terraform"
  }
}

resource "aws_subnet" "public_subnet_2" {
  vpc_id                  = aws_vpc.go_demo_vpc.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true

  tags = {
    Name       = "${var.project_name}-${var.environment}-public-2"
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "terraform"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.go_demo_vpc.id

  tags = {
    Name       = "${var.project_name}-${var.environment}-igw"
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "terraform"
  }
}

# Public Route Table
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.go_demo_vpc.id

  tags = {
    Name       = "${var.project_name}-${var.environment}-public-rt"
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "terraform"
  }
}

# Default route to IGW
resource "aws_route" "public_rt_default_route" {
  route_table_id         = aws_route_table.public_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

# Route Table Associations
resource "aws_route_table_association" "public_subnet_1_assoc" {
  subnet_id      = aws_subnet.public_subnet_1.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "public_subnet_2_assoc" {
  subnet_id      = aws_subnet.public_subnet_2.id
  route_table_id = aws_route_table.public_rt.id
}

# Security Groups
resource "aws_security_group" "alb_sg" {
  name   = "${var.project_name}-${var.environment}-alb-sg"
  vpc_id = aws_vpc.go_demo_vpc.id

  description = "Security group for ALB"

  tags = {
    Name       = "${var.project_name}-${var.environment}-alb-sg"
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "terraform"
  }
}

resource "aws_security_group_rule" "alb_ingress_http" {
  type              = "ingress"
  security_group_id = aws_security_group.alb_sg.id
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "Allow HTTP from anywhere"
}

resource "aws_security_group_rule" "alb_egress_all" {
  type              = "egress"
  security_group_id = aws_security_group.alb_sg.id
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "Allow all outbound from ALB"
}

resource "aws_security_group" "frontend_service_sg" {
  name   = "${var.project_name}-${var.environment}-frontend-sg"
  vpc_id = aws_vpc.go_demo_vpc.id

  description = "Security group for frontend ECS service"

  tags = {
    Name       = "${var.project_name}-${var.environment}-frontend-sg"
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "terraform"
  }
}

resource "aws_security_group_rule" "frontend_ingress_from_alb" {
  type                     = "ingress"
  security_group_id        = aws_security_group.frontend_service_sg.id
  source_security_group_id = aws_security_group.alb_sg.id
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  description              = "Allow ALB to talk to frontend"
}

resource "aws_security_group_rule" "frontend_egress_all" {
  type              = "egress"
  security_group_id = aws_security_group.frontend_service_sg.id
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "Allow all outbound from frontend"
}

resource "aws_security_group" "backend_service_sg" {
  name   = "${var.project_name}-${var.environment}-backend-sg"
  vpc_id = aws_vpc.go_demo_vpc.id

  description = "Security group for backend ECS service"

  tags = {
    Name       = "${var.project_name}-${var.environment}-backend-sg"
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "terraform"
  }
}

resource "aws_security_group_rule" "backend_ingress_from_alb" {
  type                     = "ingress"
  security_group_id        = aws_security_group.backend_service_sg.id
  source_security_group_id = aws_security_group.alb_sg.id
  from_port                = 8080
  to_port                  = 8080
  protocol                 = "tcp"
  description              = "Allow ALB to talk to backend"
}

resource "aws_security_group_rule" "backend_egress_all" {
  type              = "egress"
  security_group_id = aws_security_group.backend_service_sg.id
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "Allow all outbound from backend"
}

# Application Load Balancer
resource "aws_lb" "application_lb" {
  name               = "${var.project_name}-${var.environment}-alb"
  internal           = false
  load_balancer_type = "application"
  subnets            = [aws_subnet.public_subnet_1.id, aws_subnet.public_subnet_2.id]
  security_groups    = [aws_security_group.alb_sg.id]

  tags = {
    Name       = "${var.project_name}-${var.environment}-alb"
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "terraform"
  }
}

# Target Groups (use target_type = "ip" for Fargate awsvpc)
resource "aws_lb_target_group" "frontend_tg" {
  name        = "${var.project_name}-${var.environment}-frontend-tg"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.go_demo_vpc.id
  target_type = "ip"

  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200-399"
    interval            = 30
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }

  tags = {
    Name       = "${var.project_name}-${var.environment}-frontend-tg"
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "terraform"
  }
}

resource "aws_lb_target_group" "backend_tg" {
  name        = "${var.project_name}-${var.environment}-backend-tg"
  port        = 8080
  protocol    = "HTTP"
  vpc_id      = aws_vpc.go_demo_vpc.id
  target_type = "ip"

  health_check {
    path                = "/health"
    protocol            = "HTTP"
    matcher             = "200-399"
    interval            = 30
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }

  tags = {
    Name       = "${var.project_name}-${var.environment}-backend-tg"
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "terraform"
  }
}

# Listener
resource "aws_lb_listener" "http_listener" {
  load_balancer_arn = aws_lb.application_lb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.frontend_tg.arn
  }
}

# Listener Rule for /api/* -> backend
resource "aws_lb_listener_rule" "api_path_rule" {
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

# ECS Cluster
resource "aws_ecs_cluster" "go_demo_cluster" {
  name = "${var.project_name}-${var.environment}-cluster"

  tags = {
    Name       = "${var.project_name}-${var.environment}-cluster"
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "terraform"
  }
}

# IAM Role for ECS Task Execution
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "${var.project_name}-${var.environment}-ecs-task-exec-role"

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
    Name       = "${var.project_name}-${var.environment}-ecs-task-exec-role"
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "terraform"
  }
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_attachment" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# CloudWatch Log Groups
resource "aws_cloudwatch_log_group" "frontend_log_group" {
  name = "/ecs/${var.project_name}-${var.environment}-frontend"

  tags = {
    Name       = "/ecs/${var.project_name}-${var.environment}-frontend"
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "terraform"
  }
}

resource "aws_cloudwatch_log_group" "backend_log_group" {
  name = "/ecs/${var.project_name}-${var.environment}-backend"

  tags = {
    Name       = "/ecs/${var.project_name}-${var.environment}-backend"
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "terraform"
  }
}

# ECS Task Definitions
resource "aws_ecs_task_definition" "frontend_task_definition" {
  family                   = "${var.project_name}-${var.environment}-frontend"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn

  container_definitions = jsonencode([
    {
      name      = "frontend"
      image     = local.service_images["frontend-service"]
      cpu       = 256
      memory    = 512
      essential = true
      readonlyRootFilesystem = false
      portMappings = [
        {
          containerPort = 80
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
}

resource "aws_ecs_task_definition" "backend_task_definition" {
  family                   = "${var.project_name}-${var.environment}-backend"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn

  container_definitions = jsonencode([
    {
      name      = "backend"
      image     = local.service_images["backend-service"]
      cpu       = 256
      memory    = 512
      essential = true
      readonlyRootFilesystem = false
      portMappings = [
        {
          containerPort = 8080
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
}

# ECS Services
resource "aws_ecs_service" "frontend_service" {
  name            = "${var.project_name}-${var.environment}-frontend-svc"
  cluster         = aws_ecs_cluster.go_demo_cluster.id
  task_definition = aws_ecs_task_definition.frontend_task_definition.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = [aws_subnet.public_subnet_1.id, aws_subnet.public_subnet_2.id]
    security_groups = [aws_security_group.frontend_service_sg.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.frontend_tg.arn
    container_name   = "frontend"
    container_port   = 80
  }

  depends_on = [aws_lb_target_group.frontend_tg]

  tags = {
    Name       = "${var.project_name}-${var.environment}-frontend-svc"
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "terraform"
  }
}

resource "aws_ecs_service" "backend_service" {
  name            = "${var.project_name}-${var.environment}-backend-svc"
  cluster         = aws_ecs_cluster.go_demo_cluster.id
  task_definition = aws_ecs_task_definition.backend_task_definition.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = [aws_subnet.public_subnet_1.id, aws_subnet.public_subnet_2.id]
    security_groups = [aws_security_group.backend_service_sg.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.backend_tg.arn
    container_name   = "backend"
    container_port   = 8080
  }

  depends_on = [aws_lb_target_group.backend_tg]

  tags = {
    Name       = "${var.project_name}-${var.environment}-backend-svc"
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "terraform"
  }
}
