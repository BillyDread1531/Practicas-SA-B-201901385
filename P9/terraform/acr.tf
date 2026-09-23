data "azurerm_container_registry" "platform" {
  name                = "acrsa201901385"
  resource_group_name = "rg-sa-p6"
}

resource "azurerm_role_assignment" "aks_acr_pull" {
  scope                = data.azurerm_container_registry.platform.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_kubernetes_cluster.aks.kubelet_identity[0].object_id
}