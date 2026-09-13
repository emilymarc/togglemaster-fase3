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
## 5. Redis: cluster simples não suporta TLS

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
## 6. NAT Gateway: recurso além do enunciado

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
