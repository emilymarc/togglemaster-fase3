# Desafios encontrados e decisões tomadas

Registro corrido, preenchido **durante** o desenvolvimento. Alimenta o item
"breve resumo dos desafios encontrados e decisões tomadas" do relatório de
entrega da Fase 3.

Formato de cada entrada: sintoma → causa → solução adotada.

---

## 1. AWS Academy não permite criar recursos de IAM

**Sintoma.** O Terraform precisa de uma IAM Role para o cluster EKS e outra
para os node groups. Criar qualquer Role ou Policy é bloqueado na conta do
Academy.

**Causa.** Restrição de permissão do ambiente Learner Lab — política
institucional, não um erro de configuração.

**Solução.** Em vez de um bloco `resource` que cria a role, usamos um
`data source`, que **lê** um recurso já existente sem criar nem modificar:

```hcl
data "aws_iam_role" "lab_role" {
  name = "LabRole"
}
```

O ARN resultante é associado tanto ao cluster quanto ao node group. O
Terraform do projeto cria **zero** recursos de IAM.

---

## 2. Versão do Kubernetes fora de suporte

**Sintoma.**
`InvalidParameterException: unsupported Kubernetes version 1.29` no apply.

**Causa.** A AWS aposenta versões do Kubernetes continuamente. A 1.29 saiu
do suporte padrão e também do estendido, então já não é aceita para criar
clusters novos.

**Solução.** Consultamos as versões válidas antes de fixar:

```bash
aws eks describe-addon-versions --addon-name vpc-cni \
  --query 'addons[].addonVersions[].compatibilities[].clusterVersion' \
  --output text | tr '\t' '\n' | sort -uV
```

**Decisão.** Fixar uma versão explicitamente (e não deixar a AWS escolher),
para que o ambiente seja reproduzível — mas escolhendo entre as que estão em
suporte no momento do provisionamento.

---

## 3. `depends_on` não aceita variável

**Sintoma.** Os worker nodes precisam da rota do NAT Gateway para conseguir
entrar no cluster (baixam as imagens de bootstrap pela internet). A tentativa
inicial foi passar o ID do NAT para o módulo e usar
`depends_on = [var.nat_gateway_id]`.

**Causa.** `depends_on` aceita apenas referências a recursos, data sources e
módulos. Variáveis não são entidades do grafo de dependências.

**Solução.** A dependência foi declarada na **chamada do módulo**, na raiz:

```hcl
module "eks" {
  source = "./modules/eks"
  # ...
  depends_on = [module.networking]
}
```

O EKS só começa a ser criado depois que todo o módulo de rede termina — VPC,
subnets, IGW, NAT e route tables.

---

## 4. Desenvolvimento em Windows com Git Bash

Quatro incompatibilidades que custaram tempo e cujas soluções valem registro:

| Sintoma | Causa | Solução |
|---|---|---|
| `bad interpreter: /bin/sh^M` dentro dos contêineres | Windows grava CRLF; contêineres Linux não aceitam | `git config --global core.autocrlf input` + `.gitattributes` com `eol=lf` |
| `tar: This does not look like a tar archive` ao extrair o Trivy | O `tar` do Git Bash é GNU tar e não abre `.zip` | usar o bsdtar do Windows: `/c/Windows/System32/tar.exe -xf` |
| `argocd login` parece travar, sem pedir senha | Git Bash não aloca TTY para programas interativos | prefixar com `winpty` |
| `jq: command not found` | Git Bash não inclui jq | `winget install --id jqlang.jq -e` |

---

## 5. Argumentos rejeitados na chamada de módulo

**Sintoma.** `An argument named "project_name" is not expected here.`

**Causa.** Todo argumento passado a um módulo precisa de um bloco `variable`
correspondente declarado **dentro** dele. O `variables.tf` dos módulos estava
vazio.

**Solução.** Declarar as variáveis no módulo antes de chamá-lo. Adotamos a
prática de listar o que o módulo espera antes de escrever a chamada:

```bash
grep -rho 'var\.[a-z_]*' modules/<nome>/ | sort -u
```

**Erro relacionado:** `private_subnet_ids` foi declarado como `string`, mas o
módulo de rede devolve `aws_subnet.private[*].id`, que é lista. O tipo correto
é `list(string)` — com `string` a função `concat()` falha.

---

## 6. Controle de orçamento do Academy

**Sintoma.** Crédito limitado (US$ 50) contra um ambiente que custa cerca de
US$ 8,00/dia com tudo ligado. O control plane do EKS cobra ~US$ 2,40/dia
mesmo ocioso.

**Solução.** Rotina de destruição ao fim de cada sessão, documentada no
`README.md`. Destruímos EKS, bancos e rede, preservando os repositórios ECR
(reconstruí-los é barato; republicar as imagens exigiria rodar o CI de novo).

**Armadilha encontrada.** O LoadBalancer do ArgoCD é criado pelo **Kubernetes**,
não pelo Terraform — `terraform destroy` não o remove, e ele fica órfão
cobrando. A ordem correta é liberar o Service antes:

```bash
kubectl delete svc argocd-server -n argocd   # primeiro
terraform destroy ...                        # depois
```

Criamos `scripts/check-orphans.sh` para verificar, após cada destruição, se
algum recurso continua cobrando.

---

## 7. RDS bloqueado na Fase 2, liberado na Fase 3

**Contexto.** Na Fase 2 a criação de instâncias RDS foi barrada pela LabRole,
e a solução na época foi rodar PostgreSQL como Deployments no Kubernetes com
volumes EBS. A Fase 3, porém, exige explicitamente **3 instâncias RDS
provisionadas por Terraform** — então era preciso saber, antes de escrever o
módulo, se a restrição continuava valendo.

**Verificação.** Antes de qualquer código, testamos a criação direto pela CLI:

```bash
aws rds create-db-instance \
  --db-instance-identifier teste-rds \
  --db-instance-class db.t3.micro \
  --engine postgres \
  --master-username teste \
  --master-user-password TesteSenha123 \
  --allocated-storage 20 \
  --no-publicly-accessible
```

**Resultado.** A criação **funcionou**. O RDS está disponível na conta, e o
módulo `data-stores` pôde ser escrito como planejado, sem plano B.

**Precaução mantida.** Ainda assim, deixamos desligadas todas as opções do RDS
que exigem uma IAM Role própria, já que criá-las é proibido no Academy:

```hcl
monitoring_interval                 = 0      # Enhanced Monitoring
performance_insights_enabled        = false
enabled_cloudwatch_logs_exports     = []
iam_database_authentication_enabled = false
```

**Aprendizado.** Verificar uma restrição herdada em vez de assumi-la custou
cinco minutos e evitou construir uma arquitetura alternativa desnecessária.
Restrições de ambiente mudam entre fases e entre laboratórios.

---

## 8. Guia inicial divergia do projeto real

**Sintoma.** Ao revisar o plano de implementação contra o código dos serviços
e os manifestos da Fase 2, seis itens não correspondiam à realidade. Dois
teriam quebrado só em runtime, o que é o pior tipo de erro.

| Item | Plano inicial | Realidade da Fase 2 |
|---|---|---|
| Chave do DynamoDB | `eventId` + range `timestamp` (N) | `event_id` (S), sem range key |
| SQS | fila + dead letter queue | uma fila |
| Portas dos serviços | `8080` para todos | 8001, 8002, 8003, 8004, 8005 |
| Health checks | liveness `/health`, readiness `/ready` | ambos `/health` |
| Réplicas | 3 | 1 |
| Secrets | `host` e `password` separados | `DATABASE_URL` completa |

**Impacto dos dois erros silenciosos.** Com `eventId`/`timestamp` numérico,
todo `put_item` do analytics falharia com `ValidationException`. Com
readiness em `/ready` — endpoint que não existe —, todos os pods ficariam
permanentemente fora do balanceador, sem erro aparente no deploy.

**Causa.** O plano foi escrito a partir do enunciado, sem consultar o código
que já existia.

**Solução.** Revisão sistemática: extrair do código as variáveis de ambiente
realmente lidas, os atributos realmente gravados e as portas realmente
expostas, e corrigir o plano a partir disso.

```bash
# variaveis que cada servico le de verdade
grep -rhoE 'os\.Getenv\("[A-Z_]+"\)|environ\.get\("[A-Z_]+"' services/
```

**Aprendizado.** Em uma fase que reimplementa algo existente, o código
anterior é a especificação — não o enunciado. O enunciado diz *o que* provisionar;
o código diz *com quais nomes e valores*.

---

## 9. Redis: cluster simples não suporta TLS

**Sintoma.** O `evaluation-service` espera uma URL `rediss://` (com TLS), e a
Fase 2 usava um endpoint `master.*`. O recurso `aws_elasticache_cluster` não
oferece criptografia em trânsito.

**Causa.** No ElastiCache, `transit_encryption_enabled` só existe em
`aws_elasticache_replication_group`. O cluster simples sempre fala em texto
claro, e a URL seria `redis://`.

**Decisão.** Usar `aws_elasticache_replication_group` com um único nó:

```hcl
transit_encryption_enabled = true
at_rest_encryption_enabled = true
automatic_failover_enabled = false   # um no so, sem replica
```

Mantém a paridade com a Fase 2 e atende o "1 Cluster ElastiCache (Redis)" do
enunciado, ao custo de um pouco mais de configuração e um apply mais demorado.

---

## 10. NAT Gateway: recurso além do enunciado

**Contexto.** O enunciado lista, em networking, apenas VPC, Subnets, Internet
Gateway e Route Tables. O NAT Gateway não aparece.

**Por que foi incluído.** Os worker nodes ficam em subnets privadas e
precisam de saída para a internet para baixar as imagens de bootstrap do EKS.
Sem NAT, eles nunca entram no cluster — o node group fica em estado de erro.
A Fase 2 chegou à mesma conclusão (`privateNetworking: true` com NAT).

**Registro.** É a única adição de recurso além do que o enunciado pede, feita
por necessidade técnica e não por preferência. Custa cerca de US$ 1,08/dia, o
que reforça a rotina de destruição ao fim de cada sessão.

---

<!-- PRÓXIMAS ENTRADAS: acrescente abaixo conforme os desafios aparecerem.
     Sugestões do que provavelmente ainda vem:
     - imagem base com CVE crítica no scan de contêiner
     - credenciais do Academy expirando no meio do CI
     - Service em Pending por falta das tags kubernetes.io/role/elb
     - ArgoCD OutOfSync ou pods sem subir após o sync
-->
