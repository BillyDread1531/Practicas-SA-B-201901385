provider "kubectl" {
  host                   = azurerm_kubernetes_cluster.aks.kube_config[0].host
  client_certificate     = base64decode(azurerm_kubernetes_cluster.aks.kube_config[0].client_certificate)
  client_key             = base64decode(azurerm_kubernetes_cluster.aks.kube_config[0].client_key)
  cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.aks.kube_config[0].cluster_ca_certificate)
  load_config_file       = false
}

resource "kubectl_manifest" "root_app" {
  yaml_body = <<-YAML
    apiVersion: argoproj.io/v1alpha1
    kind: Application
    metadata:
      name: p9-root-app
      namespace: argocd
    spec:
      project: default
      source:
        repoURL: https://github.com/BillyDread1531/Practica-SA-P8-GitOps.git
        targetRevision: p9
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
  YAML

  depends_on = [helm_release.argocd]
}
