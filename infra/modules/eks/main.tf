resource "aws_eks_cluster" "main" {
  name = "${var.project_name}-cluster"

  # Versao herdada do cluster.yaml da Fase 2. Se a AWS recusar
  # (versoes saem de suporte), liste as validas com:
  #   aws eks describe-addon-versions --addon-name vpc-cni \
  #     --query 'addons[].addonVersions[].compatibilities[].clusterVersion' \
  #     --output text | tr '\t' '\n' | sort -uV
  version = "1.36"

  # ⬇ THE Academy line: reference, never create
  role_arn = data.aws_iam_role.lab_role.arn

  vpc_config {
    subnet_ids              = concat(var.private_subnet_ids, var.public_subnet_ids)
    endpoint_public_access  = true   # so kubectl works from your laptop
    endpoint_private_access = true
  }

  # Send cluster logs to CloudWatch — useful for the demo
  enabled_cluster_log_types = ["api", "audit"]
}