# Bloco 2 — Backend remoto no S3
#
# ATENCAO: este bloco e lido ANTES das variaveis existirem,
# entao os valores precisam ser literais (nada de var.*).
# Troque o nome do bucket pelo que voce criou com: aws s3 mb

terraform {
  required_version = ">= 1.6"

  backend "s3" {
    bucket       = "TROQUE-PELO-SEU-BUCKET"
    key          = "togglemaster/terraform.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}
