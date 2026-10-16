# ---------------------------------------------------------------------------
# Infraestructura mínima de P10: un clúster AKS de UN nodo, sin ACR, sin
# Load Balancer, sin Key Vault ni Storage de respaldos (eso era alcance de
# P9, ya entregado). El objetivo de este stack es exclusivamente sostener la
# observabilidad y el canary por métricas sobre el flujo de P8, al costo más
# bajo posible.
#
# El plano de control de AKS (SKU "Free") no tiene costo. Lo único que
# factura por hora es el nodo (ver variables.tf).
# ---------------------------------------------------------------------------

resource "azurerm_resource_group" "p10" {
  name     = "rg-sa-p10"
  location = var.location

  tags = {
    practica = "P10"
    curso    = "software-avanzado"
  }
}

resource "azurerm_kubernetes_cluster" "aks" {
  name                = "aks-sa-p10"
  location            = azurerm_resource_group.p10.location
  resource_group_name = azurerm_resource_group.p10.name
  dns_prefix          = "aks-sa-p10"
  sku_tier            = "Free"

  default_node_pool {
    name       = "system"
    node_count = var.node_count
    vm_size    = var.node_vm_size

    upgrade_settings {
      max_surge = "10%"
    }
  }

  identity {
    type = "SystemAssigned"
  }

  tags = {
    practica = "P10"
    curso    = "software-avanzado"
  }
}

provider "helm" {
  kubernetes {
    host                   = azurerm_kubernetes_cluster.aks.kube_config[0].host
    client_certificate     = base64decode(azurerm_kubernetes_cluster.aks.kube_config[0].client_certificate)
    client_key             = base64decode(azurerm_kubernetes_cluster.aks.kube_config[0].client_key)
    cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.aks.kube_config[0].cluster_ca_certificate)
  }
}

provider "kubectl" {
  host                   = azurerm_kubernetes_cluster.aks.kube_config[0].host
  client_certificate     = base64decode(azurerm_kubernetes_cluster.aks.kube_config[0].client_certificate)
  client_key             = base64decode(azurerm_kubernetes_cluster.aks.kube_config[0].client_key)
  cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.aks.kube_config[0].cluster_ca_certificate)
  load_config_file       = false
}

resource "helm_release" "argocd" {
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  version          = "10.2.1"
  namespace        = "argocd"
  create_namespace = true
  timeout          = 600

  # Instancia unica, sin HA, recursos minimos: este ArgoCD vive unas horas.
  values = [yamlencode({
    controller = { replicas = 1, resources = { requests = { cpu = "50m", memory = "128Mi" } } }
    server     = { replicas = 1, resources = { requests = { cpu = "25m", memory = "64Mi" } }, autoscaling = { enabled = false } }
    repoServer = { replicas = 1, resources = { requests = { cpu = "25m", memory = "64Mi" } } }
    applicationSet = { replicas = 1, resources = { requests = { cpu = "15m", memory = "32Mi" } } }
    redis          = { resources = { requests = { cpu = "15m", memory = "32Mi" } } }
    dex            = { enabled = false }
    notifications  = { enabled = false }
  })]
}

# Punto de entrada único del app-of-apps: a partir de aquí, ArgoCD despliega
# TODO el resto (Kyverno, Sealed Secrets, Argo Rollouts, la plataforma de
# microservicios y el stack de observabilidad) leyendo apps/ de la rama p10
# del repositorio GitOps. Sin pasos manuales adicionales.
resource "kubectl_manifest" "root_app" {
  yaml_body = <<-YAML
    apiVersion: argoproj.io/v1alpha1
    kind: Application
    metadata:
      name: p10-root-app
      namespace: argocd
    spec:
      project: default
      source:
        repoURL: ${var.gitops_repo_url}
        targetRevision: ${var.gitops_revision}
        path: apps
        directory:
          recurse: true
      destination:
        server: https://kubernetes.default.svc
        namespace: argocd
      syncPolicy:
        automated:
          prune: true
          selfHeal: true
        syncOptions:
          - CreateNamespace=true
        retry:
          limit: 10
          backoff:
            duration: 30s
            factor: 2
            maxDuration: 5m
  YAML

  depends_on = [helm_release.argocd]
}
