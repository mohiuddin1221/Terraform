# --- 1. ECS Cluster ---
resource "aws_ecs_cluster" "main" {
  name = "${var.project_name}-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled" 
  }
}

# --- 2. CloudWatch Log Group ---
resource "aws_cloudwatch_log_group" "ecs_logs" {
  name              = "/ecs/${var.project_name}"
  retention_in_days = 7
}

# --- 3. ECS Task Definition ---
resource "aws_ecs_task_definition" "app" {
  family                   = var.project_name
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  
  cpu                      = "1024" 
  memory                   = "3072" 

  execution_role_arn       = var.execution_role_arn
  task_role_arn            = var.task_role_arn

  
  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "X86_64"
  }

  container_definitions = jsonencode([
    # FastAPI APP
    {
      name      = "fastapi-app"
      image     = "691645677816.dkr.ecr.us-east-1.amazonaws.com/topu-devops-assesment@sha256:6036a6dcee7cad8be579d67f4ee3d1f1c512b262a81a9812038cfadea2995c82" 
      essential = true
      secrets = [
        {
          name      = "DATABASE_URL" 
          valueFrom = "arn:aws:ssm:us-east-1:691645677816:parameter/DATABASE_URL" 
        }
      ]
      portMappings = [
        {
          containerPort = 8000
          hostPort      = 8000
          protocol      = "tcp"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.ecs_logs.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "app"
          "awslogs-create-group"  = "true"
        }
      }
    },
    #  ADOT Collector (Sidecar)
    {
      name      = "adot-collector"
      image     = "public.ecr.aws/aws-observability/aws-otel-collector:latest"
      essential = true
      command   = ["--config=/etc/ecs/ecs-cloudwatch-xray.yaml"]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.ecs_logs.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "adot"
          "awslogs-create-group"  = "true"
        }
      }
    }
  ])
}

# # --- 4. ECS Service ---
resource "aws_ecs_service" "main" {
  name            = "${var.project_name}-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.app.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
      subnets          = [var.public_subnet_2_id] 
      security_groups  = [var.fargate_sg_id]
      assign_public_ip = true
    }

  load_balancer {
    target_group_arn = var.target_group_arn
    container_name   = "fastapi-app"
    container_port   = 8000
  }

  lifecycle {
    ignore_changes = [task_definition, desired_count]
  }
}