variable "resource_group_name" {
  description = "Resource group persistente (el mismo del backend de estado)"
  type        = string
  default     = "rg-sa-p9-backend"
}

variable "velero_storage_account_name" {
  description = "Cuenta Blob persistente con los respaldos de Velero (nombre global unico)"
  type        = string
  default     = "stp9velero201901385"
}

variable "velero_blob_container_name" {
  description = "Contenedor de respaldos de Velero"
  type        = string
  default     = "velero"
}

variable "key_vault_name" {
  description = "Key Vault que guarda la copia de las llaves de Sealed Secrets"
  type        = string
  default     = "kv-p9-201901385"
}

variable "sealed_secrets_secret_name" {
  description = "Nombre del secreto del Key Vault con las llaves de Sealed Secrets"
  type        = string
  default     = "sealed-secrets-keys"
}
