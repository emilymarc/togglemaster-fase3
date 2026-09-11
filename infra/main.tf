provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "ToggleMaster"
      ManagedBy   = "Terraform"
      Environment = var.environment
    }
  }
}

data "aws_availability_zones" "available" {
  state = "available"
}

# calling modules
module "networking" {
  source       = "./modules/networking"
  project_name = var.project_name
  azs          = slice(data.aws_availability_zones.available.names, 0, 2)
}

# ── Bloco 4 ────────────────────────────────────────────────
module "eks" {
  source       = "./modules/eks"
  project_name = var.project_name

  private_subnet_ids = module.networking.private_subnet_ids
  public_subnet_ids  = module.networking.public_subnet_ids

  # Os nodes so conseguem entrar no cluster depois que a rota do NAT
  # existe. Como o node group nao referencia o NAT em nenhum argumento,
  # a dependencia precisa ser declarada aqui — depends_on aceita
  # modulos e recursos, nunca variaveis.
  depends_on = [module.networking]
}

# ── Bloco 5 ────────────────────────────────────────────────
# module "data_stores" { source = "./modules/data-stores"  ... }
