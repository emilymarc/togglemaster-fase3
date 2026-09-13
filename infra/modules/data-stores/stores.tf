# ── Redis: cache do evaluation-service ──────────────────────
# Replication group (nao cluster simples) para manter o TLS da
# Fase 2: o servico espera rediss:// e o endpoint master.*
resource "aws_elasticache_subnet_group" "main" {
  name       = "${var.project_name}-cache-subnets"
  subnet_ids = var.private_subnet_ids
}

resource "aws_elasticache_replication_group" "redis" {
  replication_group_id = "${var.project_name}-redis"
  description          = "ToggleMaster - cache do evaluation-service"

  engine               = "redis"
  engine_version       = "7.1"
  node_type            = "cache.t3.micro"
  num_cache_clusters   = 1
  parameter_group_name = "default.redis7"
  port                 = 6379

  subnet_group_name  = aws_elasticache_subnet_group.main.name
  security_group_ids = [aws_security_group.db.id]

  # TLS em transito — e isto que faz a URL ser rediss://
  transit_encryption_enabled = true
  at_rest_encryption_enabled = true

  # Um no so; sem replica nao ha failover automatico
  automatic_failover_enabled = false
}

# ── DynamoDB: eventos gravados pelo analytics-service ───────
# O app.py grava o item com 'event_id' e 'timestamp', ambos {'S': ...}.
# So a chave precisa ser declarada — os demais atributos sao
# schemaless. Nao ha query nem scan no codigo, entao nao ha range key.
resource "aws_dynamodb_table" "analytics" {
  name         = "ToggleMasterAnalytics" # nome exigido no enunciado
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "event_id"

  attribute {
    name = "event_id"
    type = "S"
  }
}

# ── SQS: evaluation publica, analytics consome ──────────────
# Uma fila, conforme o enunciado. O analytics ja trata mensagem
# invalida deixando de apagar da fila (ver app.py).
resource "aws_sqs_queue" "events" {
  name = "${var.project_name}-events"
}
