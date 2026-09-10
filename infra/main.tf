# Bloco 2 — Provider + chamada dos modulos

provider "aws" {
  region = var.aws_region

  # Aplicado automaticamente a todo recurso criado.
  # Facilita achar tudo depois e montar a estimativa de custos.
  default_tags {
    tags = {
      Project     = "ToggleMaster"
      ManagedBy   = "Terraform"
      Environment = var.environment
    }
  }
}

# Descobre as AZs da regiao em vez de escrever na mao
data "aws_availability_zones" "available" {
  state = "available"
}

# ── Bloco 3 ────────────────────────────────────────────────
# module "networking" {
#   source       = "./modules/networking"
#   project_name = var.project_name
#   azs          = slice(data.aws_availability_zones.available.names, 0, 2)
# }

# ── Bloco 4 ────────────────────────────────────────────────
# module "eks" { source = "./modules/eks"  ... }

# ── Bloco 5 ────────────────────────────────────────────────
# module "data_stores" { source = "./modules/data-stores"  ... }
