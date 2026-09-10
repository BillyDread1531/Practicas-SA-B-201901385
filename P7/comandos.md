# Comandos utilizados - Práctica 7

## Pruebas locales

```powershell
python .\P7\tests\test_services.py
```

Resultado esperado:

```text
Ran 6 tests
OK
```

## Estado del repositorio

```powershell
git status --short
```

## Primer pipeline

```powershell
git add .github/workflows/p7-ci-cd.yml
git add P7
git commit -m "feat: pipeline CI CD practica 7"
git push origin main
```

## Versionamiento

```powershell
git tag v1.0.0
git push origin v1.0.0
```

Versión final utilizada:

```powershell
git tag v1.0.1
git push origin v1.0.1
```

## Azure AKS

Consultar estado:

```powershell
az aks show `
  --resource-group rg-sa-p6 `
  --name aks-sa-p6 `
  --query "powerState.code" `
  -o tsv
```

Obtener credenciales:

```powershell
az aks get-credentials `
  --resource-group rg-sa-p6 `
  --name aks-sa-p6 `
  --overwrite-existing
```

## Kubernetes

```powershell
kubectl config current-context
kubectl cluster-info
kubectl get nodes
kubectl get pods -n sa-p6
kubectl get svc -n sa-p6
kubectl get pvc -n sa-p6
kubectl get cronjobs -n sa-p6
```

Seguimiento de pods:

```powershell
kubectl get pods -n sa-p6 -w
```

## Reinicio de recursos

```powershell
kubectl rollout restart deployment -n sa-p6
kubectl rollout restart statefulset rabbitmq -n sa-p6
```

## Logs de RabbitMQ

```powershell
kubectl logs rabbitmq-0 -n sa-p6 --tail=120
kubectl logs rabbitmq-0 -n sa-p6 --previous --tail=120
kubectl describe pod rabbitmq-0 -n sa-p6
```

## Prueba pública

```powershell
curl.exe -i http://57.165.161.54:3000/health
```

Resultado obtenido:

```text
HTTP/1.1 200 OK

{"status":"ok","service":"gateway"}
```

## Flujo general

```text
Push / Tag
    |
    v
Build
    |
    v
Test
    |
    v
Docker Build
    |
    v
Push GHCR
    |
    v
Azure Login
    |
    v
AKS + Helm
    |
    v
Aplicación desplegada
```