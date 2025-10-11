# RECURSOS DE RED Y SEGURIDAD MÍNIMOS (DEPENDENCIAS)

# 1. Creación de la VPC (Virtual Private Cloud)
resource "aws_vpc" "vpc" {
  cidr_block = "10.0.0.0/16"
  tags = { Name = "${var.project}-vpc" }
}

# 2. Creación de la Primera Subnet Privada (AZ A)
resource "aws_subnet" "private" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "${var.aws_region}a"
  tags = { Name = "${var.project}-private-a" }
}

# 2. Creación de la Segunda Subnet Privada (AZ B)
# Necesaria para cumplir el requisito de 2 AZs de Aurora y alta disponibilidad.
resource "aws_subnet" "private_b" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "${var.aws_region}b"
  tags = { Name = "${var.project}-private-b" }
}

# 3. Grupo de Seguridad del ECS (Backend Identity)
resource "aws_security_group" "ecs_sg" {
  name   = "${var.project}-ecs-sg"
  vpc_id = aws_vpc.vpc.id
  # Solo necesita egreso (salida) para conectarse a la DB y a Internet (vía NAT)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# ----------------------------------------------------
# CONFIGURACIÓN DE SEGURIDAD Y CONEXIÓN DE AURORA
# ----------------------------------------------------

# 4. Grupo de Seguridad para la Base de Datos (DB_SG)
resource "aws_security_group" "db_sg" {
  name        = "${var.project}-db-sg"
  description = "Allows traffic from ECS tasks (backend) to Aurora DB." 
  vpc_id      = aws_vpc.vpc.id

  # Regla de entrada: Permite MySQL (3306) SOLO desde el SG del backend (ecs_sg)
  ingress {
    description     = "MySQL/Aurora access from ECS"
    from_port       = 3306 
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs_sg.id] 
  }
}

# 5. Configuración del Subnet Group para Aurora
resource "aws_db_subnet_group" "aurora_subnet_group" {
  name       = "${var.project}-aurora-subnet-group"
  # Incluye ambas subredes privadas (AZ A y AZ B).
  subnet_ids = [aws_subnet.private.id, aws_subnet.private_b.id]
}

# ----------------------------------------------------
# CREACIÓN DEL CLÚSTER DE AURORA
# ----------------------------------------------------

# 6. Creación del Clúster de Aurora 
resource "aws_rds_cluster" "aurora_cluster" {
  cluster_identifier      = "${var.project}-aurora-cluster"
  engine                  = "aurora-mysql"
  engine_mode             = "provisioned"
  master_username         = var.db_user
  master_password         = var.db_password
  database_name           = var.db_name
  db_subnet_group_name    = aws_db_subnet_group.aurora_subnet_group.name
  skip_final_snapshot     = true
  # Conexión: Solo permite el acceso del SG de la DB (db_sg)
  vpc_security_group_ids  = [aws_security_group.db_sg.id] 
}

# 7. Creación de una Instancia de Base de Datos
resource "aws_rds_cluster_instance" "aurora_instance" {
  identifier         = "${var.project}-aurora-instance"
  cluster_identifier = aws_rds_cluster.aurora_cluster.id
  instance_class     = "db.t3.medium"
  engine             = aws_rds_cluster.aurora_cluster.engine
}

# ----------------------------------------------------
# CONFIGURACIÓN DE ECR (Elastic Container Registry)
# ----------------------------------------------------

# 8. Creación del Repositorio ECR para el backend
resource "aws_ecr_repository" "backend_repo" {
  name                 = "${var.project}-backend-repo"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name = "${var.project}-backend-repo"
  }
}                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 

# ----------------------------------------------------
# RECURSOS PÚBLICOS Y NAT GATEWAY (CAMINO DE SALIDA)
# ----------------------------------------------------

# 14. Creación del Internet Gateway
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.vpc.id
  tags   = { Name = "${var.project}-gw" }
}

# 15. Creación de la Primera Subred Pública (AZ A) - ¡LA RESTAURADA!
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "${var.aws_region}a"
  map_public_ip_on_launch = true
  tags = { Name = "${var.project}-public-a" }
}

# 15. Creación de la Segunda Subred Pública (AZ B) - Requerida por ALB
resource "aws_subnet" "public_b" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = "10.0.4.0/24" # Rango CIDR nuevo y único
  availability_zone       = "${var.aws_region}b"
  map_public_ip_on_launch = true
  tags = { Name = "${var.project}-public-b" }
}

# 16. Creación de una IP Elástica (EIP) para el NAT Gateway
resource "aws_eip" "nat" {
  depends_on = [aws_internet_gateway.gw] 
}

# 17. Creación del NAT Gateway (Debe estar en la Subred Pública A)
resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public.id
  tags          = { Name = "${var.project}-nat" }
  depends_on    = [aws_subnet.public]
}

# 18. Tabla de Ruteo para la Subred Pública (Ruta a Internet)
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
}

# 19. Asociación de la Tabla de Ruteo Pública a la Subred A
resource "aws_route_table_association" "public_a_assoc" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# 19. Asociación de la Tabla de Ruteo Pública a la Subred B
resource "aws_route_table_association" "public_b_assoc" {
  subnet_id      = aws_subnet.public_b.id
  route_table_id = aws_route_table.public.id
}

# 20. Tabla de Ruteo para Subredes Privadas (Ruta a través del NAT Gateway)
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }
}

# 21. Asociación de la Tabla de Ruteo a la Primera Subred Privada
resource "aws_route_table_association" "private_a" {
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.private.id
}

# 22. Asociación de la Tabla de Ruteo a la Segunda Subred Privada
resource "aws_route_table_association" "private_b" {
  subnet_id      = aws_subnet.private_b.id
  route_table_id = aws_route_table.private.id
}

# ----------------------------------------------------
# CONFIGURACIÓN DE LOGS PARA FARGATE (CloudWatch)
# ----------------------------------------------------

# 23. Creación explícita del Grupo de Logs 
resource "aws_cloudwatch_log_group" "backend_logs" {
  name              = "/ecs/${var.project}-backend"
  retention_in_days = 7
}

# ----------------------------------------------------
# CONFIGURACIÓN DE ECS FARGATE (BACKEND RUNTIME)
# ----------------------------------------------------

# 24. Creación del Cluster de ECS
resource "aws_ecs_cluster" "main" {
  name = "${var.project}-ecs-cluster"
}

# 25. Definición del Rol de IAM para la Tarea de ECS (Execution Role)
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "${var.project}-ecs-task-exec-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Sid    = ""
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# 26. Definición de la Tarea (Task Definition) para Fargate
resource "aws_ecs_task_definition" "backend_task" {
  family                   = "${var.project}-backend-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"] 
  cpu                      = 512    
  memory                   = 1024   
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn

  container_definitions = jsonencode([
    {
      name      = "backend"
      image     = "${aws_ecr_repository.backend_repo.repository_url}:latest" 
      essential = true
      portMappings = [
        {
          containerPort = 3000
          hostPort      = 3000
        }
      ]
      environment = [
        {
          name  = "DB_HOST"
          value = aws_rds_cluster.aurora_cluster.endpoint
        },
        {
          name  = "DB_USERNAME"
          value = aws_rds_cluster.aurora_cluster.master_username
        },
        {
          name  = "DB_PASSWORD"
          value = var.db_password
        }
      ]      
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.backend_logs.name
          awslogs-region        = var.aws_region
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ])
}

# ----------------------------------------------------
# CONFIGURACIÓN DEL LOAD BALANCER (ALB)
# ----------------------------------------------------

# 28. Grupo de Seguridad del ALB (Acepta tráfico 80 desde Internet)
resource "aws_security_group" "alb_sg" {
  name   = "${var.project}-alb-sg"
  vpc_id = aws_vpc.vpc.id

  # Entrada: HTTP (80) desde CUALQUIER lugar
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Salida: Tráfico a cualquier lado (por defecto)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# 29. Actualizar SG de ECS: Permitir tráfico del ALB
resource "aws_security_group_rule" "ecs_from_alb" {
  type                     = "ingress"
  from_port                = 3000
  to_port                  = 3000
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.alb_sg.id
  security_group_id        = aws_security_group.ecs_sg.id
}

# 30. Creación del Load Balancer (ALB) - CORREGIDO: USA AMBAS SUBREDES PÚBLICAS
resource "aws_lb" "alb" {
  name               = "${var.project}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  # Usa ambas subredes públicas para alta disponibilidad
  subnets            = [aws_subnet.public.id, aws_subnet.public_b.id] 
}

# 31. Target Group (Grupo de Destino: a dónde enviar el tráfico)
resource "aws_lb_target_group" "backend_tg" {
  name        = "${var.project}-backend-tg"
  port        = 3000
  protocol    = "HTTP"
  vpc_id      = aws_vpc.vpc.id
  target_type = "ip" # Fargate usa IPs
  
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

# 32. Listener (Escuchador: Recibe el tráfico en el puerto 80 y lo reenvía)
resource "aws_lb_listener" "http_listener" {
  load_balancer_arn = aws_lb.alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.backend_tg.arn
  }
}

# 33. Creación del Servicio ECS (Despliega la tarea en Fargate)
resource "aws_ecs_service" "backend_service" {
  name            = "${var.project}-backend-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.backend_task.arn
  desired_count   = 1 
  launch_type     = "FARGATE"

  # Conecta el servicio Fargate al Target Group del ALB
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

# 34. Output para ver la URL del ALB
output "backend_url" {
  description = "La URL del Application Load Balancer para acceder al backend"
  value       = aws_lb.alb.dns_name
}