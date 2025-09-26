#ORQUESTADOR ECR
resource "aws_ecr_repository" "backend" {
  name = "${var.project}-backend"
}

resource "aws_ecr_repository" "frontend" {
  name = "${var.project}-frontend"
}

#SNS
resource "aws_sns_topic" "tasks" {
  name = "${var.project}-tasks-topic"
}

#AURORA
resource "aws_rds_subnet_group" "aurora_subnet_group" {
  name       = "${var.project}-aurora-subnet-group"
  subnet_ids = [aws_subnet.private.id]
}

resource "aws_rds_cluster" "aurora_cluster" {
  cluster_identifier      = "${var.project}-aurora-cluster"
  engine                  = "aurora-mysql"
  engine_mode             = "provisioned"
  master_username         = var.db_user
  master_password         = var.db_password
  database_name           = var.db_name
  db_subnet_group_name    = aws_rds_subnet_group.aurora_subnet_group.name
  skip_final_snapshot     = true
  vpc_security_group_ids  = [aws_security_group.ecs_sg.id]
}

resource "aws_rds_cluster_instance" "aurora_instance" {
  identifier         = "${var.project}-aurora-instance"
  cluster_identifier = aws_rds_cluster.aurora_cluster.id
  instance_class     = "db.serverless" 
  engine             = aws_rds_cluster.aurora_cluster.engine
}

#ECS cluster
resource "aws_ecs_cluster" "cluster" {
  name = "${var.project}-cluster"
}

#IAM
data "aws_iam_policy_document" "task_assume_role" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "ecs_task_execution_role" {
  name               = "${var.project}-ecs-exec-role"
  assume_role_policy = data.aws_iam_policy_document.task_assume_role.json
}

resource "aws_iam_role_policy_attachment" "ecs_exec_attach" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role" "ecs_task_role" {
  name               = "${var.project}-ecs-task-role"
  assume_role_policy = data.aws_iam_policy_document.task_assume_role.json
}


resource "aws_iam_role_policy" "task_permissions" {
  name = "${var.project}-task-policy"
  role = aws_iam_role.ecs_task_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["sns:Publish"]
        Resource = [aws_sns_topic.tasks.arn]
      }
    ]
  })
}

#VPC
resource "aws_vpc" "vpc" {
  cidr_block = "10.0.0.0/16"
  tags = { Name = "${var.project}-vpc" }
}

resource "aws_subnet" "public" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "${var.aws_region}a"
}

resource "aws_subnet" "private" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "${var.aws_region}a"
}

# ALB security
resource "aws_security_group" "alb_sg" {
  name   = "${var.project}-alb-sg"
  vpc_id = aws_vpc.vpc.id
  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# ECS Security Group
resource "aws_security_group" "ecs_sg" {
  name   = "${var.project}-ecs-sg"
  vpc_id = aws_vpc.vpc.id
  ingress {
    from_port       = 3000
    to_port         = 3000
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# ALB
resource "aws_lb" "alb" {
  name               = "${var.project}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [aws_subnet.public.id]
}

resource "aws_lb_target_group" "backend_tg" {
  name     = "${var.project}-tg"
  port     = 3000
  protocol = "HTTP"
  vpc_id   = aws_vpc.vpc.id
  health_check {
    path    = "/health"
    matcher = "200"
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.alb.arn
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.backend_tg.arn
  }
}

##Fargate Backend
resource "aws_ecs_task_definition" "backend" {
  family                   = "${var.project}-backend"
  cpu                      = "256"
  memory                   = "512"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([
    {
      name      = "backend"
      image     = "${aws_ecr_repository.backend.repository_url}:latest"
      essential = true
      portMappings = [
        {
          containerPort = 3000
          hostPort      = 3000
          protocol      = "tcp"
        }
      ]
      environment = [
        { name = "SNS_TOPIC_ARN", value = aws_sns_topic.tasks.arn },
        { name = "AWS_REGION", value = var.aws_region },
        { name = "DB_HOST", value = aws_rds_cluster.aurora_cluster.endpoint },
        { name = "DB_USER", value = var.db_user },
        { name = "DB_PASS", value = var.db_password },
        { name = "DB_NAME", value = var.db_name }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = "/ecs/${var.project}-backend"
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "backend"
        }
      }
    }
  ])
}

resource "aws_ecs_service" "backend" {
  name            = "${var.project}-backend"
  cluster         = aws_ecs_cluster.cluster.id
  task_definition = aws_ecs_task_definition.backend.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = [aws_subnet.private.id]
    security_groups = [aws_security_group.ecs_sg.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.backend_tg.arn
    container_name   = "backend"
    container_port   = 3000
  }

  depends_on = [aws_lb_listener.http]
}



