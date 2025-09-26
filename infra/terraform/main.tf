resource "aws_ecr_repository" "backend" {
  name = "${var.project}-backend"
}

resource "aws_ecr_repository" "frontend" {
  name = "${var.project}-frontend"
}

resource "aws_sns_topic" "tasks" {
  name = "${var.project}-tasks-topic"
}

resource "aws_ecs_cluster" "cluster" {
  name = "${var.project}-cluster"
  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}