output "alb_dns" {
  value = aws_lb.alb.dns_name
}

output "sns_topic_arn" {
  value = aws_sns_topic.tasks.arn
}

output "aurora_endpoint" {
  value = aws_rds_cluster.aurora_cluster.endpoint
}