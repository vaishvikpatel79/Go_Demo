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
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name        = "${var.project_name}-${var.environment}-vpc"
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "terraform"
  }
}

resource "aws_subnet" "public_subnet_1" {
  vpc_id                  = aws_vpc.go_demo_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name        = "${var.project_name}-${var.environment}-public-subnet-1"
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
    Name        = "${var.project_name}-${var.environment}-public-subnet-2"
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "terraform"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.go_demo_vpc.id

  tags = {
    Name        = "${var.project_name}-${var.environment}-igw"
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "terraform"
  }
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.go_demo_vpc.id

  tags = {
    Name        = "${var.project_name}-${var.environment}-public-rt"
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "terraform"
  }
}

resource "aws_route" "public_default_route" {
  route_table_id         = aws_route_table.public_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

resource "aws_route_table_association" "public_subnet_1_assoc" {
  subnet_id      = aws_subnet.public_subnet_1.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "public_subnet_2_assoc" {
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
    ManagedBy   = "terraform"
  }
}

resource "aws_security_group" "frontend_service_sg" {
  name   = "${var.project_name}-${var.environment}-frontend-sg"
  vpc_id = aws_vpc.go_demo_vpc.id

  tags = {
    Name        = "${var.project_name}-${var.environment}-frontend-sg"
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "terraform"
  }
}

resource "aws_security_group" "backend_service_sg" {
  name   = "${var.project_name}-${var.environment}-backend-sg"
  vpc_id = aws_vpc.go_demo_vpc.id

  tags = {
    Name        = "${var.project_name}-${var.environment}-backend-sg"
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "terraform"
  }
}

resource "aws_security_group_rule" "alb_ingress_http" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.alb_sg.id
}

resource "aws_security_group_rule" "frontend_ingress_http_from_alb" {
  type                     = "ingress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  security_group_id        = aws_security_group.frontend_service_sg.id
  source_security_group_id = aws_security_group.alb_sg.id
}

resource "aws_security_group_rule" "backend_ingress_8080_from_alb" {
  type                     = "ingress"
  from_port                = 8080
  to_port                  = 8080
  protocol                 = "tcp"
  security_group_id        = aws_security_group.backend_service_sg.id
  source_security_group_id = aws_security_group.alb_sg.id
}

resource "aws_security_group_rule" "alb_egress_all" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.alb_sg.id
}

resource "aws_security_group_rule" "frontend_egress_all" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.frontend_service_sg.id
}

resource "aws_security_group_rule" "backend_egress_all" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.backend_service_sg.id
}

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
    Name        = "${var.project_name}-${var.environment}-ecs-task-exec-role"
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "terraform"
  }
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy_attach" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_cloudwatch_log_group" "frontend_log_group" {
  name = "/ecs/${var.project_name}-${var.environment}-frontend"

  tags = {
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "terraform"
  }
}

resource "aws_cloudwatch_log_group" "backend_log_group" {
  name = "/ecs/${var.project_name}-${var.environment}-backend"

  tags = {
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "terraform"
  }
}

resource "aws_ecs_cluster" "go_demo_cluster" {
  name = "${var.project_name}-${var.environment}-cluster"

  tags = {
    Name        = "${var.project_name}-${var.environment}-cluster"
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "terraform"
  }
}

resource "aws_lb_target_group" "frontend_tg" {
  name        = "${var.project_name}-${var.environment}-frontend-tg"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.go_demo_vpc.id
  target_type = "ip"

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
    ManagedBy   = "terraform"
  }
}

resource "aws_lb" "application_load_balancer" {
  name               = "${var.project_name}-${var.environment}-alb"
  load_balancer_type = "application"
  internal           = false
  subnets            = [aws_subnet.public_subnet_1.id, aws_subnet.public_subnet_2.id]
  security_groups    = [aws_security_group.alb_sg.id]

  tags = {
    Name        = "${var.project_name}-${var.environment}-alb"
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "terraform"
  }
}

resource "aws_lb_listener" "http_listener" {
  load_balancer_arn = aws_lb.application_load_balancer.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.frontend_tg.arn
  }
}

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

resource "aws_ecs_task_definition" "frontend_task_definition" {
  family                   = "${var.project_name}-${var.environment}-frontend"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  cpu                      = tostring(var.frontend_cpu)
  memory                   = tostring(var.frontend_memory)

  container_definitions = jsonencode([
    {
      name      = "frontend"
      image     = local.service_images["go-demo-frontend-service"]
      cpu       = var.frontend_cpu
      memory    = var.frontend_memory
      essential = true
      portMappings = [
        {
          containerPort = 80
          protocol      = "tcp"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.frontend_log_group.name
          "awslogs-region"        = var.region
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])

  tags = {
    Name        = "${var.project_name}-${var.environment}-frontend-taskdef"
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "terraform"
  }
}

resource "aws_ecs_task_definition" "backend_task_definition" {
  family                   = "${var.project_name}-${var.environment}-backend"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  cpu                      = tostring(var.backend_cpu)
  memory                   = tostring(var.backend_memory)

  container_definitions = jsonencode([
    {
      name      = "backend"
      image     = local.service_images["go-demo-backend-service"]
      cpu       = var.backend_cpu
      memory    = var.backend_memory
      essential = true
      portMappings = [
        {
          containerPort = 8080
          protocol      = "tcp"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.backend_log_group.name
          "awslogs-region"        = var.region
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])

  tags = {
    Name        = "${var.project_name}-${var.environment}-backend-taskdef"
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "terraform"
  }
}

resource "aws_ecs_service" "frontend_service" {
  name            = "${var.project_name}-${var.environment}-frontend-service"
  cluster         = aws_ecs_cluster.go_demo_cluster.id
  task_definition = aws_ecs_task_definition.frontend_task_definition.arn
  desired_count   = var.frontend_desired_count

  launch_type = "FARGATE"

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
    ManagedBy   = "terraform"
  }
}

resource "aws_ecs_service" "backend_service" {
  name            = "${var.project_name}-${var.environment}-backend-service"
  cluster         = aws_ecs_cluster.go_demo_cluster.id
  task_definition = aws_ecs_task_definition.backend_task_definition.arn
  desired_count   = var.backend_desired_count

  launch_type = "FARGATE"

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
    ManagedBy   = "terraform"
  }
}
