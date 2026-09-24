# ---------------------------------------------------------------------------
# Capa PERSISTENTE de P9.
#
# Todo lo que debe sobrevivir a la destrucción del clúster vive aquí, en un
# resource group y un estado de Terraform distintos de los del clúster:
#   - Storage Account con los respaldos de Velero (destino externo al clúster)
#   - Key Vault con la copia de las llaves de Sealed Secrets
# Se aplica UNA sola vez (terraform apply); el DR nunca lo destruye.
# ---------------------------------------------------------------------------

data "azurerm_client_config" "current" {}

data "azurerm_resource_group" "backend" {
  name = var.resource_group_name
}

resource "azurerm_storage_account" "velero" {
  name                     = var.velero_storage_account_name
  resource_group_name      = data.azurerm_resource_group.backend.name
  location                 = data.azurerm_resource_group.backend.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  min_tls_version          = "TLS1_2"

  allow_nested_items_to_be_public = false

  blob_properties {
    versioning_enabled = true

    delete_retention_policy {
      days = 14
    }

    container_delete_retention_policy {
      days = 14
    }
  }

  tags = {
    practica = "P9"
    servicio = "velero-backups"
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "azurerm_storage_container" "velero" {
  name                  = var.velero_blob_container_name
  storage_account_name  = azurerm_storage_account.velero.name
  container_access_type = "private"
}

resource "azurerm_key_vault" "p9" {
  name                       = var.key_vault_name
  location                   = data.azurerm_resource_group.backend.location
  resource_group_name        = data.azurerm_resource_group.backend.name
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = "standard"
  enable_rbac_authorization  = true
  soft_delete_retention_days = 7
  purge_protection_enabled   = false

  tags = {
    practica = "P9"
    servicio = "sealed-secrets-keys"
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "azurerm_role_assignment" "kv_operator" {
  scope                = azurerm_key_vault.p9.id
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = data.azurerm_client_config.current.object_id
}

# Contenedor del secreto. El valor real (JSON con las llaves de Sealed Secrets)
# lo escribe scripts/backup-sealed-key.ps1 desde el clúster en marcha; Terraform
# solo garantiza que el secreto existe y nunca pisa el valor.
resource "azurerm_key_vault_secret" "sealed_secrets_keys" {
  name         = var.sealed_secrets_secret_name
  value        = "[]"
  key_vault_id = azurerm_key_vault.p9.id
  content_type = "application/json"

  lifecycle {
    ignore_changes = [value]
  }

  depends_on = [azurerm_role_assignment.kv_operator]
}
