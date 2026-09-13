variable "aws_region" {
  description = "AWS region for all resources"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  type    = string
  default = "togglemaster"
}

variable "environment" {
  type    = string
  default = "dev"
}

variable "services" {
  description = "The 5 ToggleMaster microservices"
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
