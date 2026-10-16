output "resource_group" {
  value = azurerm_resource_group.p10.name
}

output "cluster_name" {
  value = azurerm_kubernetes_cluster.aks.name
}

output "kube_config_raw" {
  value     = azurerm_kubernetes_cluster.aks.kube_config_raw
  sensitive = true
}
