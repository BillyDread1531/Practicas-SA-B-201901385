resource "azurerm_resource_group" "p9" {
  name     = "rg-sa-p9"
  location = "eastus"

  tags = {
    practica = "P9"
    curso    = "software-avanzado"
  }
}

resource "azurerm_kubernetes_cluster" "aks" {
  name                = "aks-sa-p9"
  location            = azurerm_resource_group.p9.location
  resource_group_name = azurerm_resource_group.p9.name
  dns_prefix          = "aks-sa-p9"
  oidc_issuer_enabled = true

  default_node_pool {
    name       = "system"
    node_count = var.node_count
    vm_size    = "Standard_D2s_v7"

    upgrade_settings {
      max_surge = "10%"
    }
  }

  identity {
    type = "SystemAssigned"
  }

  tags = {
    practica = "P9"
    curso    = "software-avanzado"
  }
}
