# Outputs consumidos fora do Terraform.
# Viram Secrets do Kubernetes no Bloco 10.

output "cluster_name" {
  description = "Use em: aws eks update-kubeconfig --name <isto>"
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  value = module.eks.cluster_endpoint
}

# DATABASE_URL pronta por servico (auth, flag, targeting)
output "database_urls" {
  sensitive = true
  value     = module.data_stores.database_urls
}

output "redis_url" {
  value = module.data_stores.redis_url
}

output "sqs_queue_url" {
  value = module.data_stores.sqs_queue_url
}

output "dynamodb_table" {
  value = module.data_stores.dynamodb_table
}

output "rds_endpoints" {
  value = module.data_stores.rds_endpoints
}

# Bloco 6 — descomente quando criar o ecr.tf
# output "ecr_repository_urls" {
#   value = { for k, v in aws_ecr_repository.services : k => v.repository_url }
# }
