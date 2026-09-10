# Disclaimer

Arquivos que **não** fazem parte da entrega da Fase 3, mas que ainda são úteis
como consulta. Nada aqui é aplicado ou versionado como solução.

| Arquivo | Por que saiu da raiz | Ainda serve para |
|---|---|---|
| `cluster.yaml` | cluster criado com eksctl | comparar com o módulo EKS do Terraform (Bloco 4) |
| `deploy.ps1` | deploy manual via script | nada — o GitOps substitui por completo |
| `docker-compose.yaml` | ambiente local da Fase 2 | rodar os serviços localmente enquanto desenvolve |
| `postgres-shared-init.sql` | ligado aos pods de Postgres | conferir schema ao migrar para RDS (Bloco 5) |
| `notes.md` | anotações da Fase 2 | consulta pessoal |
| `k8s/` | manifestos aplicados à mão | **importante**: base para escrever `gitops/` no Bloco 10 |

