# ToggleMaster — Tech Challenge Fase 3

Plataforma de *feature flags* composta por 5 microsserviços, provisionada
integralmente por código na AWS.

Esta fase substitui o provisionamento manual da Fase 2 por **Infraestrutura
como Código (Terraform)**, um **pipeline DevSecOps** com bloqueio por
vulnerabilidade, e **entrega contínua via GitOps** com ArgoCD.

> **Ambiente:** AWS Academy (Opção A) — o Terraform não cria Roles nem
> Policies de IAM; ele referencia a `LabRole` já existente na conta.

---

## Arquitetura

| Microsserviço | Linguagem | Porta | Rota | Armazenamento |
|---|---|---|---|---|
| `auth-service`       | Go     | 8001 | `/auth`      | RDS PostgreSQL (`auth_db`) |
| `flag-service`       | Python | 8002 | `/flags`     | RDS PostgreSQL (`flag_db`) |
| `targeting-service`  | Python | 8003 | `/targeting` | RDS PostgreSQL (`targeting_db`) |
| `evaluation-service` | Go     | 8004 | `/evaluate`  | ElastiCache Redis (TLS) + SQS |
| `analytics-service`  | Python | 8005 | `/analytics` | DynamoDB + SQS |

Portas, nomes e rotas são herdados da Fase 2 — não foram redefinidos. As pastas
em `services/` não levam o sufixo `-service`; ele aparece nos nomes dos
repositórios ECR e dos objetos do Kubernetes, como na Fase 2.

Todos rodam em um cluster **EKS**, dentro de uma VPC com subnets públicas e
privadas em duas zonas de disponibilidade. Os bancos ficam exclusivamente nas
subnets privadas, sem acesso público.

### Fluxo de entrega

```
push na main
  → CI: build + testes + lint
  → CI: SCA (Trivy) + SAST (gosec/bandit)      ← bloqueia se CRÍTICO
  → CI: build da imagem + scan do contêiner
  → CI: push para o ECR com a tag do commit
  → CI: atualiza a tag no repositório GitOps
  → ArgoCD detecta e sincroniza no EKS
```

O pipeline **não tem acesso ao cluster**. Ele só escreve no Git; quem aplica
no cluster é o ArgoCD, de dentro dele.

---

## Estrutura do repositório

```
.
├── services/              # os 5 microsserviços (código + Dockerfile)
├── infra/                 # Terraform
│   ├── backend.tf         # backend remoto no S3
│   ├── main.tf            # provider + chamada dos módulos
│   ├── variables.tf
│   ├── outputs.tf
│   └── modules/
│       ├── networking/    # VPC, subnets, IGW, NAT, route tables
│       ├── eks/           # cluster + node groups (usa LabRole)
│       └── data-stores/   # RDS, ElastiCache, DynamoDB, SQS
├── .github/workflows/     # pipelines de CI (um por serviço)
├── gitops/
│   ├── services/          # manifestos Kubernetes
│   └── apps/              # Applications do ArgoCD
└── _referencia-fase2/     # artefatos da Fase 2, apenas consulta
```

---

## Pré-requisitos

Desenvolvimento em **Windows com Git Bash** (não WSL).

```bash
winget install --id Hashicorp.Terraform -e
winget install --id Kubernetes.kubectl   -e
winget install --id Helm.Helm            -e
winget install --id Amazon.AWSCLI        -e
winget install --id GitHub.cli           -e
winget install --id jqlang.jq            -e
# trivy.exe e argocd.exe: baixar das releases e colocar em ~/bin
```

Configuração obrigatória do Git Bash — sem isso os contêineres Linux quebram
com `bad interpreter: /bin/sh^M`:

```bash
git config --global core.autocrlf input
```

Comandos interativos (que pedem senha) precisam de `winpty`:

```bash
winpty argocd login ...
```


---

## Como executar

### 1. Credenciais do AWS Academy

O Academy rotaciona as credenciais a cada sessão do laboratório. Copie o bloco de **AWS Details → AWS CLI** para `~/.aws/credentials` e confirme:

```bash
aws sts get-caller-identity
```

### 2. Bucket de estado

Criado manualmente, fora do Terraform (ele precisa existir antes do `init`):

```bash
aws s3 mb s3://togglemaster-tfstate-25783 --region us-east-1
aws s3api put-bucket-versioning \
  --bucket togglemaster-tfstate-25783 \
  --versioning-configuration Status=Enabled
```

### 3. Provisionar

```bash
cd infra
terraform init
terraform plan
terraform apply
```

O EKS leva de 10 a 15 minutos. Depois:

```bash
aws eks update-kubeconfig --name togglemaster-cluster --region us-east-1
kubectl get nodes
```

---

## ⚠ Rotina de custo — ler antes de encerrar o dia

O orçamento do Academy é limitado e o **control plane do EKS cobra mesmo
parado** (~US$ 2,40/dia). Com tudo ligado 24h o ambiente custa cerca de
**US$ 8,00/dia**; trabalhando por sessões e destruindo ao final, o total dos
três dias fica em torno de **US$ 9**.

### Custo por recurso (aproximado, us-east-1)

| Recurso | US$/dia |
|---|---|
| EKS control plane | 2,40 |
| 2× t3.medium (nodes) | 2,00 |
| 3× RDS db.t3.micro | 1,30 |
| NAT Gateway | 1,08 |
| LoadBalancer do ArgoCD | 0,54 |
| ElastiCache t3.micro | 0,41 |
| Armazenamento (EBS + RDS) | 0,34 |
| **Total** | **~8,00** |

### Ao encerrar cada sessão

**A ordem importa.** O LoadBalancer do ArgoCD é criado pelo Kubernetes, não
pelo Terraform — se o cluster for destruído antes, ele fica órfão cobrando
sem nada conectado, e o `terraform destroy` não o remove.

```bash
# 1. Libera o LoadBalancer pelo Kubernetes (só a partir do Bloco 11)
kubectl delete svc argocd-server -n argocd

# 2. Destrói o que custa, preservando os repositórios ECR e as imagens
cd infra
terraform destroy -auto-approve \
  -target=module.eks \
  -target=module.data_stores \
  -target=module.networking

# 3. Confere que não sobrou nada cobrando
bash scripts/check-orphans.sh
```

> **Nunca apague o bucket S3 de estado.** Ele não é gerenciado pelo Terraform,
> então o `destroy` não o toca — mas apagá-lo à mão significa que o Terraform
> esquece que é dono de tudo, e você recomeça do zero.

### Ao retomar no dia seguinte

```bash
# 1. Renovar credenciais do Academy (elas expiraram)
aws sts get-caller-identity

# 2. Reconstruir (~20 min)
cd infra && terraform apply -auto-approve

# 3. Reapontar o kubectl — o endpoint do cluster é novo
aws eks update-kubeconfig --name togglemaster-cluster --region us-east-1
kubectl get nodes
```

Duas coisas **não** voltam sozinhas, porque viviam dentro do cluster
destruído: os **Secrets do Kubernetes** e o **ArgoCD**. A partir do Bloco 11,
a retomada inclui recriá-los. Os endpoints mudam a cada `apply`, então os
valores saem sempre dos outputs do Terraform — nunca copiados à mão:

```bash
kubectl apply -f ../gitops/shared/namespace.yaml

for svc in auth flag targeting; do
  kubectl create secret generic ${svc}-service-secret -n togglemaster \
    --from-literal=DATABASE_URL="$(terraform output -json database_urls | jq -r .$svc)"
done

kubectl create secret generic evaluation-service-secret -n togglemaster \
  --from-literal=REDIS_URL="$(terraform output -raw redis_url)" \
  --from-literal=AWS_SQS_URL="$(terraform output -raw sqs_queue_url)"

kubectl create secret generic analytics-service-secret -n togglemaster \
  --from-literal=AWS_SQS_URL="$(terraform output -raw sqs_queue_url)"
```

Depois disso, reinstalar o ArgoCD via Helm e reaplicar as Applications.

> Por isso o **Dia 3 é o único dia para deixar o ambiente ligado**:
> reinstalar o ArgoCD e ressincronizar as 5 Applications custa ~20 minutos, e
> esse não é um tempo que se queira gastar na manhã da gravação. Destrua
> **depois** de gravar.

### Pausa curta (sem destruir)

Economiza ~US$ 3,30/dia em segundos, mas o control plane continua cobrando.
Serve para algumas horas, não para a noite:

```bash
aws eks update-nodegroup-config \
  --cluster-name togglemaster-cluster \
  --nodegroup-name togglemaster-nodes \
  --scaling-config minSize=0,desiredSize=0,maxSize=4

for db in auth flag targeting; do
  aws rds stop-db-instance --db-instance-identifier togglemaster-${db}-db
done
```

Para retomar, repita com `desiredSize=2` e `start-db-instance`.

---

## Decisões técnicas

| Decisão | Motivo |
|---|---|
| `data "aws_iam_role" "lab_role"` em vez de criar role | O AWS Academy proíbe criar Roles/Policies de IAM. O data source **lê** a LabRole existente e a associa ao cluster e aos node groups. |
| Backend S3 com `use_lockfile` | Trava nativa do S3, sem precisar de tabela DynamoDB só para lock. |
| Opções avançadas do RDS desligadas | `monitoring_interval`, `performance_insights` e export de logs exigem IAM Role própria. Deixá-las ligadas faz a criação falhar com erro de permissão que parece bloqueio do RDS. |
| Tags imutáveis no ECR | Uma imagem nunca é sobrescrita, então rollback é sempre seguro. |
| `services/` sem o sufixo `-service` | Os filtros `paths:` dos workflows apontam para `services/<nome>/**`. |
| Redis como `aws_elasticache_replication_group`, não cluster simples | Só o replication group suporta TLS em trânsito. O `evaluation-service` espera `rediss://`, como na Fase 2. |
| DynamoDB apenas com hash key `event_id` (String) | É o atributo que o `analytics/app.py` grava. Não há `query` nem `scan` no código, então uma range key seria peso morto. |
| Uma única fila SQS, sem dead letter queue | O enunciado pede uma fila. O `analytics` já trata mensagem inválida deixando de removê-la. |
| NAT Gateway, embora não listado no enunciado | Sem saída para a internet, os nodes nas subnets privadas não baixam as imagens de bootstrap e não entram no cluster. A Fase 2 usou a mesma solução. |
| Terraform devolve `DATABASE_URL` pronta | Os serviços leem uma URL completa, não host e senha separados. Montar no output evita remontar na criação dos Secrets. |

O registro completo dos problemas enfrentados, com sintoma, causa e solução,
fica em **[`docs/DESAFIOS.md`](docs/DESAFIOS.md)** — é a fonte do item
"desafios encontrados e decisões tomadas" do relatório de entrega.

---

## Status

- [x] Estrutura do repositório
- [x] Backend remoto no S3
- [x] Módulo de networking (VPC, subnets, IGW, NAT, rotas)
- [x] Módulo EKS (cluster + node groups com LabRole)
- [x] Módulo data-stores (RDS, ElastiCache, DynamoDB, SQS)
- [ ] Repositórios ECR
- [ ] Pipelines de CI com DevSecOps
- [ ] Manifestos GitOps
- [ ] ArgoCD e sincronização automática

---

## Entregáveis

- **Vídeo de demonstração:** _(link a adicionar)_
- **Repositório GitOps:** _(link a adicionar)_
- **Relatório de entrega:** _(link a adicionar)_

## Participantes

_(nomes a adicionar)_
