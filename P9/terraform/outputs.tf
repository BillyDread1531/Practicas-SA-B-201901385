output "cluster_name" {
  value = azurerm_kubernetes_cluster.aks.name
}

output "resource_group" {
  value = azurerm_resource_group.p9.name
}

output "kube_config_raw" {
  value     = azurerm_kubernetes_cluster.aks.kube_config_raw
  sensitive = true
}

output "velero_storage_account" {
  value = data.azurerm_storage_account.velero.name
}

output "velero_schedule" {
  value = "p9-platform (${var.velero_schedule}, retencion ${var.velero_retention})"
}
