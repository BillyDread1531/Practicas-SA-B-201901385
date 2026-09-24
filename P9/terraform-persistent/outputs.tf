output "velero_storage_account" {
  value = azurerm_storage_account.velero.name
}

output "velero_container" {
  value = azurerm_storage_container.velero.name
}

output "key_vault" {
  value = azurerm_key_vault.p9.name
}

output "sealed_secrets_secret" {
  value = azurerm_key_vault_secret.sealed_secrets_keys.name
}
