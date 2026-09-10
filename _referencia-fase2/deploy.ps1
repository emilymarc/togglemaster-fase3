# ToggleMaster — Deploy Script
# Rode da raiz do projeto: .\deploy.ps1

$CLUSTER_NAME = "togglemaster-cluster"
$REGION = "us-east-1"

Write-Host "Atualizando kubeconfig..." -ForegroundColor Cyan
aws eks update-kubeconfig --region $REGION --name $CLUSTER_NAME

Write-Host "Instalando Metrics Server..." -ForegroundColor Cyan
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

Write-Host "Instalando Nginx Ingress Controller..." -ForegroundColor Cyan
kubectl apply -f k8s/nginx-ingress.yaml

Write-Host "Aguardando Nginx ficar pronto..." -ForegroundColor Cyan
kubectl wait --namespace ingress-nginx `
  --for=condition=ready pod `
  --selector=app.kubernetes.io/component=controller `
  --timeout=180s

Write-Host "Criando StorageClass..." -ForegroundColor Cyan
kubectl apply -f k8s/storageclass.yaml

Write-Host "Criando Namespace..." -ForegroundColor Cyan
kubectl apply -f k8s/namespace.yaml

Write-Host "Criando PostgreSQL..." -ForegroundColor Cyan
kubectl apply -f k8s/postgres/auth-postgres.yaml
kubectl apply -f k8s/postgres/flag-postgres.yaml
kubectl apply -f k8s/postgres/targeting-postgres.yaml

Write-Host "Aguardando PostgreSQL ficar pronto..." -ForegroundColor Cyan
kubectl wait --for=condition=ready pod `
  --selector=app=auth-postgres `
  --namespace=togglemaster `
  --timeout=120s
kubectl wait --for=condition=ready pod `
  --selector=app=flag-postgres `
  --namespace=togglemaster `
  --timeout=120s
kubectl wait --for=condition=ready pod `
  --selector=app=targeting-postgres `
  --namespace=togglemaster `
  --timeout=120s

Write-Host "Aplicando Secrets e ConfigMaps..." -ForegroundColor Cyan
kubectl apply -f k8s/auth-service/secret.yaml
kubectl apply -f k8s/auth-service/configmap.yaml
kubectl apply -f k8s/flag-service/secret.yaml
kubectl apply -f k8s/flag-service/configmap.yaml
kubectl apply -f k8s/targeting-service/secret.yaml
kubectl apply -f k8s/targeting-service/configmap.yaml
kubectl apply -f k8s/evaluation-service/secret.yaml
kubectl apply -f k8s/evaluation-service/configmap.yaml
kubectl apply -f k8s/analytics-service/secret.yaml
kubectl apply -f k8s/analytics-service/configmap.yaml

Write-Host "Aplicando Deployments e Services..." -ForegroundColor Cyan
kubectl apply -f k8s/auth-service/deployment.yaml
kubectl apply -f k8s/auth-service/service.yaml
kubectl apply -f k8s/flag-service/deployment.yaml
kubectl apply -f k8s/flag-service/service.yaml
kubectl apply -f k8s/targeting-service/deployment.yaml
kubectl apply -f k8s/targeting-service/service.yaml
kubectl apply -f k8s/evaluation-service/deployment.yaml
kubectl apply -f k8s/evaluation-service/service.yaml
kubectl apply -f k8s/analytics-service/deployment.yaml
kubectl apply -f k8s/analytics-service/service.yaml

Write-Host "Aplicando Ingress e HPA..." -ForegroundColor Cyan
kubectl apply -f k8s/ingress.yaml
kubectl apply -f k8s/hpa.yaml

Write-Host "`nDeploy concluido! Verificando pods..." -ForegroundColor Green
kubectl get pods -n togglemaster
kubectl get ingress -n togglemaster