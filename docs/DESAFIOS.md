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

<!-- PRÓXIMAS ENTRADAS: acrescente abaixo conforme os desafios aparecerem.
     Sugestões do que provavelmente ainda vem:
     - RDS bloqueado ou não pela LabRole (e as flags que exigem IAM Role)
     - imagem base com CVE crítica no scan de contêiner
     - credenciais do Academy expirando no meio do CI
     - Service em Pending por falta das tags kubernetes.io/role/elb
     - ArgoCD OutOfSync ou pods sem subir após o sync
-->
