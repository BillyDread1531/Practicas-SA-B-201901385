# --- Capa persistente (P9/terraform-persistent). Se lee, nunca se crea aqui. ---

variable "persistent_resource_group" {
  description = "Resource group persistente que aloja respaldos y Key Vault"
  type        = string
  default     = "rg-sa-p9-backend"
}

variable "velero_storage_account_name" {
  description = "Cuenta Blob externa al clúster (capa persistente) usada por Velero"
  type        = string
  default     = "stp9velero201901385"
}

variable "velero_blob_container_name" {
  description = "Contenedor donde Velero almacena los respaldos"
  type        = string
  default     = "velero"
}

variable "key_vault_name" {
  description = "Key Vault con la copia de las llaves de Sealed Secrets"
  type        = string
  default     = "kv-p9-201901385"
}

variable "sealed_secrets_secret_name" {
  description = "Secreto del Key Vault con las llaves de Sealed Secrets"
  type        = string
  default     = "sealed-secrets-keys"
}

# --- Respaldos ---

variable "velero_schedule" {
  description = "Expresion cron UTC para el respaldo programado"
  type        = string
  default     = "0 */6 * * *"
}

variable "velero_retention" {
  description = "Retencion de cada respaldo de Velero"
  type        = string
  default     = "720h"
}

# --- GitOps ---

variable "gitops_repo_url" {
  description = "Repositorio GitOps publico que contiene el app-of-apps (carpeta apps/)"
  type        = string
  default     = "https://github.com/BillyDread1531/Practica-SA-P8-GitOps.git"
}

variable "gitops_revision" {
  description = "Rama del repositorio GitOps"
  type        = string
  default     = "p9"
}

# --- Capacidad ---

variable "node_count" {
  description = "Nodos del clúster. La cuota regional de la suscripción (4 vCPU, 2 x Standard_D2s_v7) impide un tercer nodo; la capacidad N+1 se logra ajustando los requests para que UN nodo aloje todo el sistema."
  type        = number
  default     = 2
}
