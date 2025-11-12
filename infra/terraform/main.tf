# RECURSOS DE RED Y SEGURIDAD MÍNIMOS (DEPENDENCIAS)

resource "aws_vpc" "vpc" {
  cidr_block = "10.0.0.0/16"
  tags = { Name = "${var.project}-vpc" }
}

resource "aws_subnet" "private" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "${var.aws_region}a"
  tags = { Name = "${var.project}-private-a" }
}

resource "aws_subnet" "private_b" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "${var.aws_region}b"
  tags = { Name = "${var.project}-private-b" }
}

resource "aws_security_group" "ecs_sg" {
  name   = "${var.project}-ecs-sg"
  vpc_id = aws_vpc.vpc.id
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "db_sg" {
  name        = "${var.project}-db-sg"
  description = "Allows traffic from ECS tasks (backend) to Aurora DB."
  vpc_id      = aws_vpc.vpc.id
  ingress {
    description     = "MySQL/Aurora access from ECS"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs_sg.id]
  }
}

resource "aws_db_subnet_group" "aurora_subnet_group" {
  name       = "${var.project}-aurora-subnet-group"
  subnet_ids = [aws_subnet.private.id, aws_subnet.private_b.id]
}

resource "aws_rds_cluster" "aurora_cluster" {
  cluster_identifier      = "${var.project}-aurora-cluster"
  engine                  = "aurora-mysql"
  engine_mode             = "provisioned"
  master_username         = var.db_user
  master_password         = var.db_password
  database_name           = var.db_name
  db_subnet_group_name    = aws_db_subnet_group.aurora_subnet_group.name
  skip_final_snapshot     = true
  vpc_security_group_ids  = [aws_security_group.db_sg.id]
}

resource "aws_rds_cluster_instance" "aurora_instance" {
  identifier         = "${var.project}-aurora-instance"
  cluster_identifier = aws_rds_cluster.aurora_cluster.id
  instance_class     = "db.t3.medium"
  engine             = aws_rds_cluster.aurora_cluster.engine
}

# ECR
resource "aws_ecr_repository" "backend_repo" {
  name                 = "${var.project}-backend-repo"
  image_tag_mutability = "MUTABLE"
  image_scanning_configuration { scan_on_push = true }
  tags = { Name = "${var.project}-backend-repo" }
}

# RED PÚBLICA Y NAT

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.vpc.id
  tags   = { Name = "${var.project}-gw" }
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "${var.aws_region}a"
  map_public_ip_on_launch = true
  tags = { Name = "${var.project}-public-a" }
}

resource "aws_subnet" "public_b" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = "10.0.4.0/24"
  availability_zone       = "${var.aws_region}b"
  map_public_ip_on_launch = true
  tags = { Name = "${var.project}-public-b" }
}

resource "aws_eip" "nat" {
  depends_on = [aws_internet_gateway.gw]
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public.id
  tags          = { Name = "${var.project}-nat" }
  depends_on    = [aws_subnet.public]
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
}

resource "aws_route_table_association" "public_a_assoc" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_b_assoc" {
  subnet_id      = aws_subnet.public_b.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.vpc.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }
}

resource "aws_route_table_association" "private_a" {
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "private_b" {
  subnet_id      = aws_subnet.private_b.id
  route_table_id = aws_route_table.private.id
}

# LOGS Y MONITOREO

resource "aws_cloudwatch_log_group" "backend_logs" {
  name              = "/ecs/${var.project}-backend"
  retention_in_days = 7
}

resource "aws_sns_topic" "backend_notifications" {
  name = "${var.project}-backend-topic"
}

resource "aws_cloudwatch_metric_alarm" "cpu_high" {
  alarm_name          = "${var.project}-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = 60
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "Alerta de alto consumo CPU"
  alarm_actions       = [aws_sns_topic.backend_notifications.arn]
}

# ECS FARGATE

resource "aws_ecs_cluster" "main" {
  name = "${var.project}-ecs-cluster"
}

resource "aws_iam_role" "ecs_task_execution_role" {
  name = "${var.project}-ecs-task-exec-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Sid    = ""
      Principal = { Service = "ecs-tasks.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy_attachment" "ecs_task_cloudwatch" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchFullAccess"
}

resource "aws_iam_role_policy_attachment" "ecs_task_sns" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSNSFullAccess"
}

resource "aws_elasticache_subnet_group" "cache_subnet_group" {
  name       = "${var.project}-cache-subnet-group"
  subnet_ids = [aws_subnet.private.id, aws_subnet.private_b.id]
}

resource "aws_elasticache_cluster" "cache" {
  cluster_id           = "${var.project}-cache"
  engine               = "redis"
  node_type            = "cache.t3.micro"
  num_cache_nodes      = 1
  parameter_group_name = "default.redis7"
  subnet_group_name    = aws_elasticache_subnet_group.cache_subnet_group.name
  security_group_ids   = [aws_security_group.ecs_sg.id]
}

resource "aws_ecs_task_definition" "backend_task" {
  family                   = "${var.project}-backend-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 512
  memory                   = 1024
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  container_definitions = jsonencode([{
    name      = "backend"
    image     = "${aws_ecr_repository.backend_repo.repository_url}:latest"
    essential = true
    portMappings = [{ containerPort = 3000, hostPort = 3000 }]
    environment = [
      { name = "DB_HOST", value = aws_rds_cluster.aurora_cluster.endpoint },
      { name = "DB_USERNAME", value = aws_rds_cluster.aurora_cluster.master_username },
      { name = "DB_PASSWORD", value = var.db_password },
      { name = "CACHE_ENDPOINT", value = aws_elasticache_cluster.cache.configuration_endpoint_address },
      { name = "SNS_TOPIC_ARN", value = aws_sns_topic.backend_notifications.arn }
    ]
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        awslogs-group         = aws_cloudwatch_log_group.backend_logs.name
        awslogs-region        = var.aws_region
        awslogs-stream-prefix = "ecs"
      }
    }
  }])
}

# LOAD BALANCER

resource "aws_security_group" "alb_sg" {
  name   = "${var.project}-alb-sg"
  vpc_id = aws_vpc.vpc.id
  ingress {
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

resource "aws_security_group_rule" "ecs_from_alb" {
  type                     = "ingress"
  from_port                = 3000
  to_port                  = 3000
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.alb_sg.id
  security_group_id        = aws_security_group.ecs_sg.id
}

resource "aws_lb" "alb" {
  name               = "${var.project}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [aws_subnet.public.id, aws_subnet.public_b.id]
}

resource "aws_lb_target_group" "backend_tg" {
  name        = "${var.project}-backend-tg"
  port        = 3000
  protocol    = "HTTP"
  vpc_id      = aws_vpc.vpc.id
  target_type = "ip"
  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

resource "aws_lb_listener" "http_listener" {
  load_balancer_arn = aws_lb.alb.arn
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.backend_tg.arn
  }
}

resource "aws_ecs_service" "backend_service" {
  name            = "${var.project}-backend-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.backend_task.arn
  desired_count   = 1
  launch_type     = "FARGATE"
  load_balancer {
    target_group_arn = aws_lb_target_group.backend_tg.arn
    container_name   = "backend"
    container_port   = 3000
  }
  network_configuration {
    security_groups  = [aws_security_group.ecs_sg.id]
    subnets          = [aws_subnet.private.id, aws_subnet.private_b.id]
    assign_public_ip = false
  }
}

# WAF Y API GATEWAY

resource "aws_wafv2_web_acl" "waf" {
  name  = "${var.project}-waf"
  scope = "REGIONAL"

  default_action {
    allow {}
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${var.project}-waf"
    sampled_requests_enabled   = true
  }

  rule {
    name     = "AWS-AWSManagedRulesCommonRuleSet"
    priority = 1
    override_action {
      none {}
    }
    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AWSManagedRulesCommonRuleSet"
      sampled_requests_enabled   = true
    }
  }
}

resource "aws_wafv2_web_acl_association" "waf_alb_assoc" {
  resource_arn = aws_lb.alb.arn
  web_acl_arn  = aws_wafv2_web_acl.waf.arn

  depends_on = [aws_lb.alb]
}

resource "aws_apigatewayv2_api" "main" {
  name          = "${var.project}-api"
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_integration" "alb_integration" {
  api_id           = aws_apigatewayv2_api.main.id
  integration_type = "HTTP_PROXY"
  integration_uri  = "http://${aws_lb.alb.dns_name}"
  integration_method = "ANY"
  payload_format_version = "1.0"
}

resource "aws_apigatewayv2_route" "default_route" {
  api_id    = aws_apigatewayv2_api.main.id
  route_key = "ANY /{proxy+}"
  target    = "integrations/${aws_apigatewayv2_integration.alb_integration.id}"
}

resource "aws_apigatewayv2_stage" "default_stage" {
  api_id      = aws_apigatewayv2_api.main.id
  name        = "$default"
  auto_deploy = true
}

output "backend_url" {
  description = "La URL pública del API Gateway (proxy hacia el ALB)"
  value       = aws_apigatewayv2_api.main.api_endpoint
}
