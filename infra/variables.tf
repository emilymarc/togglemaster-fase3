# Bloco 2 — Variaveis compartilhadas

variable "aws_region" {
  description = "Regiao AWS de todos os recursos"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Prefixo de todos os recursos"
  type        = string
  default     = "togglemaster"
}

variable "environment" {
  type    = string
  default = "hml"
}

variable "services" {
  description = "Os 5 microsservicos — usado para ECR (bloco 6)"
  type        = list(string)
  default     = ["auth", "flag", "targeting", "evaluation", "analytics"]
}

# Bloco 5 — credenciais dos bancos. Definidas em terraform.tfvars,
# que esta no .gitignore e NUNCA deve ser commitado.
variable "db_username" {
  type      = string
  sensitive = true
}

variable "db_password" {
  type      = string
  sensitive = true
}
