# Valores consumidos pela raiz e, depois, pelos Secrets do
# Kubernetes no Bloco 10.

# Os servicos leem UMA URL completa em DATABASE_URL — nao host e
# senha separados. Montar aqui evita remontar na mao depois.
output "database_urls" {
  description = "postgres://user:senha@host:5432/<svc>_db, por servico"
  sensitive   = true
  value = {
    for k, db in aws_db_instance.postgres :
    k => "postgres://${var.db_username}:${var.db_password}@${db.endpoint}/${k}_db"
  }
}

# rediss:// (com TLS), igual a Fase 2
output "redis_url" {
  value = "rediss://${aws_elasticache_replication_group.redis.primary_endpoint_address}:6379"
}

output "sqs_queue_url" {
  value = aws_sqs_queue.events.url
}

output "dynamodb_table" {
  value = aws_dynamodb_table.analytics.name
}

output "rds_endpoints" {
  description = "Endpoints crus, para inspecao e troubleshooting"
  value       = { for k, v in aws_db_instance.postgres : k => v.endpoint }
}
