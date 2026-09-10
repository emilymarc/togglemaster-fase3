# Outputs consumidos fora do Terraform.
# Os endpoints viram Secrets do Kubernetes no Bloco 10.

# output "cluster_name"        { value = module.eks.cluster_name }
# output "rds_endpoints"       { value = module.data_stores.rds_endpoints }
# output "redis_endpoint"      { value = module.data_stores.redis_endpoint }
# output "ecr_repository_urls" { value = { for k, v in aws_ecr_repository.services : k => v.repository_url } }
