output "aurora_endpoint" {
  description = "El Endpoint del clúster de Aurora para que el backend se conecte."
  value       = aws_rds_cluster.aurora_cluster.endpoint
}